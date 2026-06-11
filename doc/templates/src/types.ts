export type SubSystem = 'francophone' | 'anglophone';
export type Track = 'general' | 'technique';
export type AuthProvider = 'google' | 'apple' | 'guest';

export interface UserProfile {
  name: string;
  authProvider?: AuthProvider;
  subSystem: SubSystem;
  track: Track;
  phone?: string;
  school?: string; // Pour rechercher l'école
  levelId: string;
  serieId?: string; // Appliqué si Francophone >= 2nde ou Technique (FR & EN)
  subjectIds?: string[]; // Appliqué si Anglophone General
}

export interface Level {
  id: string;
  label: string;
  description?: string;
  requiresOrientation: boolean;
}

export interface Serie {
  id: string;
  name: string;
  desc: string;
  track?: Track;
}

export interface Subject {
  id: string;
  name: string;
  mandatory?: boolean;
}
