import json
with open('scripts/firebase_seed/data/seed_3e.json', encoding='utf-8') as f:
    data = json.load(f)
for subject in data['subjects']:
    for ch in subject.get('chapters', []):
        has_fiche = bool(ch.get('fiche'))
        status = 'YES' if has_fiche else 'NO'
        print('  ' + ch['chapterId'].ljust(32) + '  fiche=' + status + '  ' + subject['subjectId'])
