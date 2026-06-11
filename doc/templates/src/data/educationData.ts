import { Level, Serie, Subject } from '../types';

// ========================
// SYSTEME FRANCOPHONE
// ========================

// Niveaux ESG & ESTP
export const FR_LEVELS: Level[] = [
  { id: 'tle', label: 'Terminale (BAC)', requiresOrientation: true },
  { id: '1ere', label: '1ère (Probatoire)', requiresOrientation: true },
  { id: '2nde', label: '2nde', requiresOrientation: true },
  { id: '3e', label: '3ème (BEPC)', requiresOrientation: false },
  { id: '4e', label: '4ème', requiresOrientation: false },
  { id: '5e', label: '5ème', requiresOrientation: false },
  { id: '6e', label: '6ème', requiresOrientation: false },
];

// Séries ESG 2nde
export const FR_SERIES_2NDE: Serie[] = [
  { id: '2nde_c', name: '2nde C (Scientifique)', desc: 'Mathématiques, Physique, SVT en dominante' },
  { id: '2nde_a', name: '2nde A (Littéraire)', desc: 'Lettres, Langues, Sciences Humaines' },
];

// Séries ESG Cycle Terminal (1ère & Tle)
export const FR_SERIES_CYCLE_TERMINAL: Serie[] = [
  { id: 'c', name: 'Série C', desc: 'Mathématiques, Physique-Chimie' },
  { id: 'd', name: 'Série D', desc: 'SVT, Mathématiques, Sciences physiques' },
  { id: 'a4', name: 'Série A4', desc: 'Lettres, Langues, Philosophie' },
  { id: 'ti', name: 'Série TI', desc: 'Technologies de l\'Information' },
];

// Séries ESTP (Lycée Technique)
export const FR_TECH_SERIES: Serie[] = [
  { id: 'f2', name: 'Spécialité F2', desc: 'Électronique et mesures' },
  { id: 'f3', name: 'Spécialité F3', desc: 'Électrotechnique' },
  { id: 'f4', name: 'Spécialité F4', desc: 'Génie Civil' },
  { id: 'cg', name: 'G3 (CG)', desc: 'Comptabilité et Gestion' },
  { id: 'ses', name: 'SES', desc: 'Sciences Économiques et Sociales' },
];

// ========================
// SYSTEME ANGLOPHONE
// ========================

// Niveaux GCE (General)
export const EN_LEVELS: Level[] = [
  { id: 'u6', label: 'Upper Sixth (A-Level)', requiresOrientation: true },
  { id: 'l6', label: 'Lower Sixth', requiresOrientation: true },
  { id: 'form5', label: 'Form 5 (O-Level)', requiresOrientation: true },
  { id: 'form4', label: 'Form 4', requiresOrientation: false },
  { id: 'form3', label: 'Form 3', requiresOrientation: false },
  { id: 'form2', label: 'Form 2', requiresOrientation: false },
  { id: 'form1', label: 'Form 1', requiresOrientation: false },
];

// Niveaux TVEE (Technical)
export const EN_TECH_LEVELS: Level[] = [
  { id: 'tve_al_yr2', label: 'Upper Sixth Tech (AL)', requiresOrientation: true },
  { id: 'tve_al_yr1', label: 'Lower Sixth Tech', requiresOrientation: true },
  { id: 'tve_il_yr4', label: 'Form 5 Tech (IL)', requiresOrientation: true },
  { id: 'tve_il_yr3', label: 'Form 4 Tech', requiresOrientation: true },
  { id: 'tve_il_yr2', label: 'Form 3 Tech', requiresOrientation: true },
  { id: 'tve_il_yr1', label: 'Form 2 Tech', requiresOrientation: true },
  { id: 'tve_il_yr0', label: 'Form 1 Tech', requiresOrientation: true },
];

// Spécialités TVEE (Technical)
export const EN_TECH_SERIES: Serie[] = [
  { id: 'tve_acct', name: 'Accounting', desc: 'Commercial Specialties' },
  { id: 'tve_elec', name: 'Electrical Technology', desc: 'Industrial Specialties' },
  { id: 'tve_mech', name: 'Mechanical Engineering', desc: 'Industrial Specialties' },
  { id: 'tve_he', name: 'Home Economics', desc: 'Service / Domestic Specialties' },
];

// O-Level Subjects (General)
export const EN_O_LEVEL_SUBJECTS: Subject[] = [
  { id: 'eng', name: 'English Language', mandatory: true },
  { id: 'fre', name: 'French', mandatory: true },
  { id: 'mat', name: 'Mathematics', mandatory: true },
  { id: 'bio', name: 'Biology', mandatory: false },
  { id: 'che', name: 'Chemistry', mandatory: false },
  { id: 'phy', name: 'Physics', mandatory: false },
  { id: 'his', name: 'History', mandatory: false },
  { id: 'geo', name: 'Geography', mandatory: false },
  { id: 'eco', name: 'Economics', mandatory: false },
  { id: 'csc', name: 'Computer Science', mandatory: false },
  { id: 'rel', name: 'Religious Studies', mandatory: false },
];

// A-Level Subjects (General)
export const EN_A_LEVEL_SUBJECTS: Subject[] = [
  { id: 'eng', name: 'English Language', mandatory: false },
  { id: 'mat', name: 'Pure Maths With Mechanics', mandatory: false },
  { id: 'fma', name: 'Further Mathematics', mandatory: false },
  { id: 'bio', name: 'Biology', mandatory: false },
  { id: 'che', name: 'Chemistry', mandatory: false },
  { id: 'phy', name: 'Physics', mandatory: false },
  { id: 'eco', name: 'Economics', mandatory: false },
  { id: 'his', name: 'History', mandatory: false },
  { id: 'geo', name: 'Geography', mandatory: false },
  { id: 'ict', name: 'ICT', mandatory: false },
];
