/// Modele leger d'entree ecole utilise par [SchoolSearchWithAdd] et ses callers.
///
/// `id` : identifiant ferme :
///   - Document Firestore `schools/{id}` si ecole presente au catalogue.
///   - `school_requests/{autoId}` si l'utilisateur a propose un ajout custom
///     (champ `isPending` = true).
///
/// `name` : libelle UI affiche tel quel (deja localise et capitalise par le caller).
///
/// `isPending` : indicateur que cet enregistrement est une demande d'ajout en
/// attente de moderation admin (cf. story E1bis-6 + Cloud Function backend).
class SchoolEntry {
  const SchoolEntry({
    required this.id,
    required this.name,
    this.isPending = false,
  });

  final String id;
  final String name;
  final bool isPending;

  @override
  bool operator ==(Object other) =>
      other is SchoolEntry &&
      other.id == id &&
      other.name == name &&
      other.isPending == isPending;

  @override
  int get hashCode => Object.hash(id, name, isPending);

  @override
  String toString() =>
      'SchoolEntry(id: $id, name: $name, isPending: $isPending)';
}
