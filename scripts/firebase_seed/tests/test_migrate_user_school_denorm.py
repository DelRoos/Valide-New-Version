"""Tests pytest pour Story 1.5.d — migrate_user_school_denorm.py.

Execution :
    cd scripts/firebase_seed
    pytest tests/test_migrate_user_school_denorm.py -v

Approche : injection d'un fake Firestore client en memoire (pas de connexion
reseau). Les tests valident :
  - Idempotence : 2 runs sur la meme fixture -> 2eme run = 0 nouvelle migration
  - Skip user dont schoolId pointe vers une ecole absente (log warning)
"""

from __future__ import annotations

import sys
from pathlib import Path
from typing import Optional
from unittest.mock import MagicMock

import pytest

# Charger le module migrate_user_school_denorm pour appeler migrate_users_school_denorm.
SCRIPT_DIR = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(SCRIPT_DIR))
from migrate_user_school_denorm import migrate_users_school_denorm  # noqa: E402


# =====================================================================
# Fake Firestore minimaliste (in-memory, suffisant pour migrate_users_school_denorm)
# =====================================================================


class _FakeDocSnapshot:
    def __init__(self, doc_id: str, data: Optional[dict]):
        self.id = doc_id
        self._data = data

    @property
    def exists(self) -> bool:
        return self._data is not None

    def to_dict(self) -> Optional[dict]:
        return dict(self._data) if self._data is not None else None


class _FakeDocRef:
    def __init__(self, store: dict, collection: str, doc_id: str):
        self._store = store
        self._coll = collection
        self._id = doc_id

    def get(self) -> _FakeDocSnapshot:
        data = self._store.get(self._coll, {}).get(self._id)
        return _FakeDocSnapshot(self._id, data)

    def set(self, payload: dict, merge: bool = False) -> None:
        if not merge:
            self._store.setdefault(self._coll, {})[self._id] = dict(payload)
            return
        existing = self._store.setdefault(self._coll, {}).get(self._id, {})
        merged = dict(existing)
        merged.update(payload)
        self._store[self._coll][self._id] = merged


class _FakeCollectionRef:
    def __init__(self, store: dict, name: str):
        self._store = store
        self._name = name

    def document(self, doc_id: str) -> _FakeDocRef:
        return _FakeDocRef(self._store, self._name, doc_id)

    def stream(self):
        for doc_id, data in self._store.get(self._name, {}).items():
            yield _FakeDocSnapshot(doc_id, data)


class _FakeFirestoreClient:
    def __init__(self, store: dict):
        self._store = store

    def collection(self, name: str) -> _FakeCollectionRef:
        return _FakeCollectionRef(self._store, name)


@pytest.fixture
def fake_db(monkeypatch):
    """Renvoie un client Firestore fake + le store inspectable.

    Le SERVER_TIMESTAMP est mocke par une string sentinel pour eviter la
    dependance reelle a firestore.SERVER_TIMESTAMP (qui est resolu cote
    serveur). Les tests verifient la presence du champ updatedAt, pas sa
    valeur.
    """
    store: dict = {}
    # Monkeypatch SERVER_TIMESTAMP pour eviter side-effect.
    import migrate_user_school_denorm as module
    monkeypatch.setattr(
        module.firestore, "SERVER_TIMESTAMP", "__SERVER_TIMESTAMP__"
    )
    return _FakeFirestoreClient(store), store


# =====================================================================
# Fixtures donnees
# =====================================================================


@pytest.fixture
def seeded_store(fake_db):
    """Seed 4 users + 2 schools pour les scenarios standard."""
    db, store = fake_db
    store["schools"] = {
        "school_lycee_bonaberi": {
            "name": "Lycee Bilingue de Bonaberi",
            "city": "Douala",
            "region": "Littoral",
            "subSystem": "both",
            "isValidated": True,
        },
        "school_lycee_joss": {
            "name": "Lycee Joss",
            "city": "Douala",
            "region": "Littoral",
            "subSystem": "francophone",
            "isValidated": True,
        },
    }
    store["users"] = {
        # User legacy a migrer (schoolId mais pas schoolCity).
        "uid_alice_legacy": {
            "uid": "uid_alice_legacy",
            "schoolId": "school_lycee_bonaberi",
            # schoolCity / schoolRegion / schoolName absents.
        },
        # User deja migre (schoolCity present) -> skip idempotent.
        "uid_bob_migrated": {
            "uid": "uid_bob_migrated",
            "schoolId": "school_lycee_joss",
            "schoolCity": "Douala",
            "schoolRegion": "Littoral",
            "schoolName": "Lycee Joss",
        },
        # User sans schoolId -> ignore (no_school_id).
        "uid_charlie_no_school": {
            "uid": "uid_charlie_no_school",
            "schoolId": None,
        },
        # User legacy pointant vers une ecole supprimee -> skip warning.
        "uid_dave_orphan": {
            "uid": "uid_dave_orphan",
            "schoolId": "school_deleted_ghost",
        },
    }
    return db, store


# =====================================================================
# Test 1 — Idempotence : 2 runs successifs -> 2eme run 0 migration
# =====================================================================


def test_migration_idempotent(seeded_store, capsys):
    """Migration alice -> 1 doc ecrit ; 2eme run -> 0 doc ecrit (already_done)."""
    db, store = seeded_store

    # Run 1.
    stats1 = migrate_users_school_denorm(db, dry_run=False)
    assert stats1["scanned"] == 4
    assert stats1["migrated"] == 1, "Seul alice doit etre migre au run 1"
    assert stats1["already_done"] == 1, "bob est deja a jour"
    assert stats1["no_school_id"] == 1, "charlie n'a pas de schoolId"
    assert stats1["skipped_missing_school"] == 1, "dave reference une ecole absente"

    # Verifier que alice a bien recu les 3 champs cosmetiques.
    alice = store["users"]["uid_alice_legacy"]
    assert alice["schoolCity"] == "Douala"
    assert alice["schoolRegion"] == "Littoral"
    assert alice["schoolName"] == "Lycee Bilingue de Bonaberi"
    assert "updatedAt" in alice

    # Run 2 — idempotence.
    stats2 = migrate_users_school_denorm(db, dry_run=False)
    assert stats2["scanned"] == 4
    assert stats2["migrated"] == 0, "Aucune nouvelle migration attendue au run 2"
    assert stats2["already_done"] == 2, "alice ET bob sont maintenant deja migres"


# =====================================================================
# Test 2 — Skip user dont schoolId reference une ecole absente
# =====================================================================


def test_migration_skip_user_with_missing_school(seeded_store, capsys):
    """User dont schoolId pointe vers school absente -> skip + log warning."""
    db, store = seeded_store

    stats = migrate_users_school_denorm(db, dry_run=False)

    # Le user dave doit etre dans skipped_missing_school.
    assert stats["skipped_missing_school"] == 1

    # Le user dave NE doit PAS avoir recu les 3 champs cosmetiques.
    dave = store["users"]["uid_dave_orphan"]
    assert "schoolCity" not in dave
    assert "schoolRegion" not in dave
    assert "schoolName" not in dave

    # Verifier que le warning a ete print.
    captured = capsys.readouterr()
    assert "[WARN]" in captured.out
    assert "school_deleted_ghost" in captured.out
