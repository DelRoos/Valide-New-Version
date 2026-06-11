import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { ArrowLeft, Check, School, Briefcase, GraduationCap, Map, Book, Search, Plus, User, Sparkles, PartyPopper, CheckCircle2, ChevronRight, BrainCircuit, XCircle, Library, Wrench, Atom, Calculator, Languages, Globe, Palette, FlaskConical, BookOpen, BookText } from 'lucide-react';
import { UserProfile } from '../types';
import { 
  FR_LEVELS, EN_LEVELS, EN_TECH_LEVELS,
  FR_SERIES_2NDE, FR_SERIES_CYCLE_TERMINAL, FR_TECH_SERIES, EN_TECH_SERIES,
  EN_O_LEVEL_SUBJECTS, EN_A_LEVEL_SUBJECTS
} from '../data/educationData';
import onboardingImage from '../assets/images/onboarding_hero_1781128407337.png';
import confetti from 'canvas-confetti';

const btnClasses = "w-full flex items-center justify-center p-4 rounded-xl font-bold transition-all disabled:opacity-50 disabled:cursor-not-allowed text-[18px]";
const primaryBtn = `${btnClasses} bg-primary text-white shadow-[0_8px_20px_rgba(37,99,235,0.25)] active:scale-95`;

const fakeSchoolsFR = ["Lycée Joss de Douala", "Lycée Bilingue d'Essos", "Collège Libermann", "Lycée Technique de Bassa", "Collège de la Salle"];
const fakeSchoolsEN = ["GBHS Bamenda", "Bilingual Grammar School Molyko", "Sasse College", "CCAST Bambili", "PCSS Buea"];

const getSubjectIcon = (name: string) => {
  const n = name.toLowerCase();
  if (n.includes('math') || n.includes('calc') || n.includes('acct') || n.includes('compt')) return Calculator;
  if (n.includes('phys') || n.includes('scien')) return Atom;
  if (n.includes('chem') || n.includes('bio') || n.includes('chim')) return FlaskConical;
  if (n.includes('eco') || n.includes('comm') || n.includes('ges')) return Briefcase;
  if (n.includes('tech') || n.includes('meca') || n.includes('elec') || n.includes('f ')) return Wrench;
  if (n.includes('geo') || n.includes('hist')) return Globe;
  if (n.includes('art') || n.includes('draw')) return Palette;
  if (n.includes('comp') || n.includes('ict') || n.includes('info')) return BrainCircuit;
  if (n.includes('litt') || n.includes('lettre') || n.includes('lang') || n.includes('fre') || n.includes('eng')) return Languages;
  return BookOpen;
};

export default function OnboardingFlow({ onComplete }: { onComplete: (profile: UserProfile) => void }) {
  const [step, setStep] = useState(0);
  
  const [profile, setProfile] = useState<Partial<UserProfile>>({
    subSystem: 'francophone',
    track: 'general',
  });
  
  const [searchSchool, setSearchSchool] = useState('');
  const [toast, setToast] = useState<string | null>(null);

  const isEN = profile.subSystem === 'anglophone';
  const isFR = !isEN;
  const isTech = profile.track === 'technique';
  
  const currentLevels = isFR ? FR_LEVELS : (isTech ? EN_TECH_LEVELS : EN_LEVELS);
  const availableSchools = isEN ? fakeSchoolsEN : fakeSchoolsFR;
  const filteredSchools = availableSchools.filter(s => s.toLowerCase().includes(searchSchool.toLowerCase()));
  const canvasRef = React.useRef<HTMLCanvasElement>(null);

  useEffect(() => {
    if (step === 9 && canvasRef.current) {
      const duration = 2500;
      const end = Date.now() + duration;
      const myConfetti = confetti.create(canvasRef.current, {
        resize: true,
        useWorker: true
      });

      const frame = () => {
        myConfetti({
          particleCount: 4,
          angle: 60,
          spread: 55,
          origin: { x: 0 },
          colors: ['#2563EB', '#16A34A', '#D97706', '#0EA5E9']
        });
        myConfetti({
          particleCount: 4,
          angle: 120,
          spread: 55,
          origin: { x: 1 },
          colors: ['#3B82F6', '#22C55E', '#F59E0B', '#38BDF8']
        });

        if (Date.now() < end) {
          requestAnimationFrame(frame);
        }
      };
      
      frame();

      const timer = setTimeout(() => {
        onComplete(profile as UserProfile);
      }, 3500);
      return () => clearTimeout(timer);
    }
  }, [step]);

  const currentLevelLabel = profile.levelId ? currentLevels.find(l => l.id === profile.levelId)?.label : '';
  const firstName = profile.name ? profile.name.split(' ')[0] : 'Champion';

  // Translations
  const t = {
    sysTitle: isEN ? 'Choose Your System' : 'Quelle section suis-tu ?',
    
    introTitle: 'Espace Scolaire 237',
    introDesc: isEN ? 'From lower secondary to high school. Your ultimate study companion.' : 'Du premier cycle au lycée. Ton compagnon d\'étude ultime pour exceller.',
    feat1Title: isEN ? 'Complete Courses' : 'Cours Complets',
    feat1Desc: isEN ? 'Structured lessons & summaries' : 'Leçons structurées et résumés',
    feat2Title: isEN ? 'Dedicated Tutor' : 'Répétiteur Dédié',
    feat2Desc: isEN ? 'Thousands of solved exercises' : 'Des milliers d\'exercices corrigés',
    feat3Title: isEN ? 'AI Assistant' : 'Assistant Intelligent',
    feat3Desc: isEN ? '24/7 personalized help' : 'Aide personnalisée 24h/24 et 7j/7',
    introNext: isEN ? 'Get Started' : 'Commencer',

    authTitle: isEN ? 'Create your account' : 'Sécurise ton espace',
    authDesc: isEN ? 'Save your progress and access your workspace from anywhere.' : 'Sauvegarde ta progression et accède à ton espace depuis n\'importe où.',
    btnGoogle: isEN ? 'Continue with Google' : 'Continuer avec Google',
    btnApple: isEN ? 'Continue with Apple' : 'Continuer avec Apple',
    btnGuest: isEN ? 'Continue as Guest' : 'Continuer comme visiteur',

    nameTitle: isEN ? 'Your Name' : 'Ton Nom',
    nameDesc: isEN ? 'How should we call you?' : 'Comment doit-on t\'appeler ?',
    namePlaceholder: isEN ? 'Your full name' : 'Ton nom complet',
    phoneTitle: isEN ? 'Phone Number' : 'Ton Téléphone',
    phoneDesc: isEN ? 'Secure your account.' : 'Pour sécuriser ton compte.',
    phonePlaceholder: isEN ? 'Phone number' : 'Numéro de téléphone',

    trackTitle: isEN ? 'Select your track' : 'Quel est ton enseignement ?',
    trackDesc: isEN ? 'General or Technical education.' : 'Enseignement général ou technique.',
    general: isEN ? 'General' : 'Général',
    technical: isEN ? 'Technical' : 'Technique',

    classTitle: isEN ? 'What class are you in?' : 'En quelle classe es-tu ?',
    classDesc: isEN ? 'Select your current level.' : 'Sélectionne ton niveau actuel pour cette année.',

    orientTech: isEN ? 'Your TVEE Specialty' : 'Ta série Technique',
    orientFrGen: isEN ? 'Your series' : 'Ta série',
    orientEnGen: isEN ? 'Pick your subjects' : 'Choisis tes matières',
    orientDescTech: isEN ? 'This shapes your timetable.' : 'Cette sélection configure ton espace.',
    orientDescEn: isEN ? 'Customize your subjects (Min 6).' : 'Choisis tes matières (Min 6).',
    coreLocked: isEN ? 'Core subjects are locked' : 'Matières obligatoires verrouillées',

    schoolTitle: isEN ? 'Which school do you attend?' : 'Tu fréquentes quelle école ?',
    schoolDesc: isEN ? 'Find your school to connect with your mates.' : 'Trouve ton école (optionnel).',
    schoolPlaceholder: isEN ? 'Ex: GBHS Bamenda...' : 'Ex: Lycée Joss, Collège...',
    schoolAdd: isEN ? 'Add' : 'Ajouter',
    schoolToast: isEN ? 'School added!' : 'École ajoutée !',
    schoolConfirm: isEN ? 'Confirm my school' : 'Confirmer mon école',
    schoolSkip: isEN ? 'Skip for now' : 'Passer cette étape',

    btnNext: isEN ? 'Continue' : 'Continuer',
    btnValidate: isEN ? 'Validate choices' : 'Valider mon choix',
    
    successTitle: isEN ? `All set, ${firstName}!` : `C'est tout bon, ${firstName} !`,
    successDesc: isEN ? `Your workspace for ${currentLevelLabel} is ready. Time to grab those top grades.` : `Ton espace pour le niveau ${currentLevelLabel} est configuré, plus qu'à péter les scores.`,
    btnStart: isEN ? 'Start App' : 'Entrer dans l\'appli'
  };

  const showToast = (msg: string) => {
    setToast(msg);
    setTimeout(() => setToast(null), 3500);
  };

  const handleLevelSelect = (levelId: string, requiresOrientation: boolean) => {
    let initialSubjects: string[] = [];
    if (isEN && !isTech) {
      if (levelId === 'form5') initialSubjects = EN_O_LEVEL_SUBJECTS.filter(s => s.mandatory).map(s => s.id);
      if (levelId === 'upper_sixth') initialSubjects = EN_A_LEVEL_SUBJECTS.filter(s => s.mandatory).map(s => s.id);
    }
    setProfile(p => ({ ...p, levelId, serieId: undefined, subjectIds: initialSubjects }));
  };

  const isNextDisabled = () => {
    if (step === 0) return !profile.subSystem;
    if (step === 2) return !profile.track;
    if (step === 3) return !profile.levelId;
    if (step === 4) {
      if (isFR || isTech) return !profile.serieId;
      return !profile.subjectIds || profile.subjectIds.length < 6;
    }
    if (step === 6) return !profile.name;
    if (step === 8) return !profile.school;
    return false;
  };

  const handleNext = () => {
    if (step === 3) {
       const levelRef = currentLevels.find(l => l.id === profile.levelId);
       if (!levelRef?.requiresOrientation) setStep(5);
       else setStep(4);
    } else if (step === 4) {
       setStep(5);
    } else {
       setStep(s => s + 1);
    }
  };

  const handleBack = () => {
    if (step === 0) {
       // handle back from step 0 is disabled, handled outside
    } else if (step === 5) {
       const levelRef = currentLevels.find(l => l.id === profile.levelId);
       if (!levelRef?.requiresOrientation) setStep(3);
       else setStep(4);
    } else if (step === 6) {
       setStep(5);
    } else {
       setStep(s => Math.max(0, s - 1));
    }
  };

  const configStepsActive = (step >= 2 && step <= 4) || (step >= 6 && step <= 8);
  const progress = step <= 4 ? Math.max(0, ((step - 1) / 3) * 100) : Math.max(0, ((step - 5) / 3) * 100);

  const stepsContent = [
    // ------------------------------------
    // STEP 0: System Selection
    // ------------------------------------
    <div key="step-0" className="flex flex-col h-full bg-bg">
      <div className="flex-1 flex flex-col justify-center px-6 max-w-lg mx-auto w-full pb-32">
        <div className="w-16 h-16 bg-primary-soft rounded-2xl flex items-center justify-center text-primary mb-6 shadow-[0_8px_30px_rgba(37,99,235,0.1)]">
           <Map size={32} />
        </div>
        <div className="space-y-2 mb-10">
          <h2 className="text-[22px] sm:text-[26px] font-black text-ink tracking-tight leading-[1.1]">{t.sysTitle}</h2>
        </div>
        <div className="space-y-4">
          <SelectionCard 
            selected={profile.subSystem === 'francophone'}
            onClick={() => { setProfile(p => ({ ...p, subSystem: 'francophone' })); }}
            title="Francophone"
            icon={null}
          />
          <SelectionCard 
            selected={profile.subSystem === 'anglophone'}
            onClick={() => { setProfile(p => ({ ...p, subSystem: 'anglophone' })); }}
            title="Anglophone"
            icon={null}
          />
        </div>
      </div>
    </div>,

    // ------------------------------------
    // STEP 1: Features Intro
    // ------------------------------------
    <div key="step-1" className="flex flex-col min-h-max bg-bg pt-0">
      <div className="relative w-full aspect-[4/3] max-w-lg mx-auto bg-primary-soft">
        <img 
          src={onboardingImage} 
          alt="Student studying" 
          className="w-full h-full object-cover shadow-soft"
        />
        <div className="absolute inset-0 bg-gradient-to-t from-bg via-bg/40 to-transparent" />
      </div>
      
      <div className="flex-1 flex flex-col px-6 max-w-lg mx-auto w-full -mt-16 relative z-10 pb-40">
        <h1 className="text-[34px] md:text-[38px] font-black leading-[1.05] tracking-tight text-ink mb-3 text-center drop-shadow-sm">
           {t.introTitle}
        </h1>
        <p className="text-[16px] font-semibold text-ink-soft mb-8 leading-snug text-center px-4">
           {t.introDesc}
        </p>

        <div className="space-y-4 w-full">
           <div className="flex items-center gap-5 p-4 bg-white/70 backdrop-blur-xl rounded-[24px] border border-white shadow-[0_8px_30px_rgba(15,23,42,0.04)]">
              <div className="w-12 h-12 shrink-0 bg-primary-soft rounded-[16px] flex items-center justify-center text-primary">
                 <Book size={24} />
              </div>
              <div>
                 <p className="font-bold text-ink text-[16px] leading-tight">{t.feat1Title}</p>
                 <p className="font-semibold text-ink-soft text-[14px] mt-0.5">{t.feat1Desc}</p>
              </div>
           </div>
           
           <div className="flex items-center gap-5 p-4 bg-white/70 backdrop-blur-xl rounded-[24px] border border-white shadow-[0_8px_30px_rgba(15,23,42,0.04)]">
              <div className="w-12 h-12 shrink-0 bg-success-soft rounded-[16px] flex items-center justify-center text-success">
                 <GraduationCap size={24} />
              </div>
              <div>
                 <p className="font-bold text-ink text-[16px] leading-tight">{t.feat2Title}</p>
                 <p className="font-semibold text-ink-soft text-[14px] mt-0.5">{t.feat2Desc}</p>
              </div>
           </div>

           <div className="flex items-center gap-5 p-4 bg-white/70 backdrop-blur-xl rounded-[24px] border border-white shadow-[0_8px_30px_rgba(15,23,42,0.04)]">
              <div className="w-12 h-12 shrink-0 bg-warning-soft rounded-[16px] flex items-center justify-center text-warning-ink">
                 <BrainCircuit size={24} />
              </div>
              <div>
                 <p className="font-bold text-ink text-[16px] leading-tight">{t.feat3Title}</p>
                 <p className="font-semibold text-ink-soft text-[14px] mt-0.5">{t.feat3Desc}</p>
              </div>
           </div>
        </div>
      </div>
    </div>,

    // ------------------------------------
    // STEP 2: Track (Général / Technique)
    // ------------------------------------
    <div key="step-2" className="flex flex-col h-full px-6 text-center relative max-h-full pb-32">
      <div className="-mx-6 px-6 sticky top-0 bg-bg z-20 pt-4 pb-4 mb-4">
         <h2 className="text-[22px] sm:text-[26px] font-black text-ink tracking-tight leading-[1.1] max-w-lg mx-auto">{t.trackTitle}</h2>
      </div>
      <div className="flex-1 flex flex-col max-w-lg mx-auto w-full pb-32">
         <div className="grid grid-cols-1 gap-4">
           <SelectionCard 
             selected={profile.track === 'general'}
             onClick={() => setProfile(p => ({ ...p, track: 'general' }))}
             title={t.general}
             icon={<Library size={24} />}
           />
           <SelectionCard 
             selected={profile.track === 'technique'}
             onClick={() => setProfile(p => ({ ...p, track: 'technique' }))}
             title={t.technical}
             icon={<Wrench size={24} />}
           />
         </div>
      </div>
    </div>,

    // ------------------------------------
    // STEP 3: Class
    // ------------------------------------
    <div key="step-3" className="flex flex-col h-full px-6 relative max-h-full">
      <div className="-mx-6 px-6 sticky top-0 bg-bg z-20 pt-4 pb-4 mb-4 text-center">
        <h2 className="text-[22px] sm:text-[26px] font-black text-ink tracking-tight leading-[1.1] max-w-lg mx-auto">
          {t.classTitle}
        </h2>
      </div>

      <div className="grid grid-cols-1 gap-3 max-w-lg mx-auto w-full pb-32">
        {currentLevels.map((level) => {
          let classIcon = <Book size={20} />;
          if (['tle', '3e', 'form5', 'u6'].includes(level.id) || level.id.includes('yr2')) classIcon = <GraduationCap size={20} />;

          return (
          <SelectionCard 
             key={level.id}
             selected={profile.levelId === level.id}
             onClick={() => handleLevelSelect(level.id, level.requiresOrientation)}
             title={level.label}
             icon={classIcon}
          />
        )})}
      </div>
    </div>,

    // ------------------------------------
    // STEP 4: Orientation (Série / Matières)
    // ------------------------------------
    <div key="step-4" className="flex flex-col flex-1 px-6 relative">
      <div className="-mx-6 px-6 sticky top-0 bg-bg z-20 pt-4 pb-4 mb-4 text-center">
        <h2 className="text-[22px] sm:text-[26px] font-black text-ink tracking-tight leading-[1.1] max-w-lg mx-auto">
          {isTech ? t.orientTech : isFR ? t.orientFrGen : t.orientEnGen}
        </h2>
      </div>

      <div className="max-w-lg mx-auto w-full pb-48">
        {isTech ? (
          <div className="grid gap-4">
             {(isFR ? FR_TECH_SERIES : EN_TECH_SERIES).map(renderSerieItem)}
          </div>
        ) : isFR ? (
          <div className="grid gap-4">
            {(profile.levelId === '2nde' ? FR_SERIES_2NDE : FR_SERIES_CYCLE_TERMINAL).map(renderSerieItem)}
          </div>
        ) : (
          <div className="space-y-4">
             <div className="text-[13px] font-bold text-warning-ink uppercase tracking-wider bg-warning-soft px-4 py-3 rounded-xl mb-6 shadow-soft flex items-center justify-between">
                <span>{t.coreLocked}</span>
                <span className={`px-2 py-1 rounded-lg bg-white/50 text-[12px] font-black ${(profile.subjectIds?.length || 0) < 6 ? 'text-warning-ink' : 'text-success'}`}>
                   {(profile.subjectIds?.length || 0)} / Min 6
                </span>
             </div>
             
             <div className="space-y-6">
                <div>
                  <h3 className="text-[15px] font-black text-ink-soft mb-3 ml-1 uppercase tracking-wider">Mandatory (Core)</h3>
                  <div className="grid grid-cols-1 gap-3">
                  {(profile.levelId === 'form5' ? EN_O_LEVEL_SUBJECTS : EN_A_LEVEL_SUBJECTS).filter(s => s.mandatory).map((sub) => {
                      const IconComp = getSubjectIcon(sub.name);
                      return (
                      <div 
                        key={sub.id} 
                        className={`flex items-center gap-3 p-3 rounded-[16px] transition-all cursor-not-allowed overflow-hidden border-primary bg-primary-soft shadow-soft ring-1 ring-primary/20 opacity-90`}
                      >
                         <div className={`shrink-0 w-8 h-8 rounded-lg flex items-center justify-center bg-primary text-white`}>
                           <IconComp size={16} />
                         </div>
                         <div className="flex-1 min-w-0">
                            <p className="font-bold text-[14px] leading-tight truncate text-primary">{sub.name}</p>
                         </div>
                         <div className={`shrink-0 w-5 h-5 rounded flex items-center justify-center border bg-primary border-primary text-white`}>
                           <Check size={12} strokeWidth={3} />
                         </div>
                      </div>
                  )})}
                  </div>
                </div>

                <div>
                  <h3 className="text-[15px] font-black text-ink-soft mb-3 ml-1 uppercase tracking-wider">Electives</h3>
                  <div className="grid grid-cols-1 gap-3">
                  {(profile.levelId === 'form5' ? EN_O_LEVEL_SUBJECTS : EN_A_LEVEL_SUBJECTS).filter(s => !s.mandatory).map((sub) => {
                      const IconComp = getSubjectIcon(sub.name);
                      const isSelected = (profile.subjectIds||[]).includes(sub.id);
                      return (
                      <div 
                        key={sub.id} 
                        onClick={() => {
                          const current = profile.subjectIds || [];
                          const nextList = current.includes(sub.id) ? current.filter(id => id !== sub.id) : [...current, sub.id];
                          setProfile(p => ({ ...p, subjectIds: nextList }));
                        }}
                        className={`flex items-center gap-3 p-3 rounded-[16px] transition-all cursor-pointer overflow-hidden
                          ${isSelected ? 'border-primary bg-primary-soft shadow-soft ring-1 ring-primary/20 scale-[1.01]' : 'border-transparent bg-white hover:bg-gray-50 shadow-soft'}
                        `}
                      >
                         <div className={`shrink-0 w-8 h-8 rounded-lg flex items-center justify-center ${isSelected ? 'bg-primary text-white' : 'bg-bg text-ink-soft'}`}>
                           <IconComp size={16} />
                         </div>
                         <div className="flex-1 min-w-0">
                            <p className={`font-bold text-[14px] leading-tight truncate ${isSelected ? 'text-primary' : 'text-ink'}`}>{sub.name}</p>
                         </div>
                         <div className={`shrink-0 w-5 h-5 rounded flex items-center justify-center border
                           ${isSelected ? 'bg-primary border-primary text-white' : 'border-muted'}
                         `}>
                           {isSelected && <Check size={12} strokeWidth={3} />}
                         </div>
                      </div>
                  )})}
                  </div>
                </div>
             </div>
          </div>
        )}
      </div>
    </div>,

    // ------------------------------------
    // STEP 5: Auth
    // ------------------------------------
    <div key="step-5" className="flex flex-col h-full bg-bg px-6 pb-40 relative">
      <div className="-mx-6 px-6 sticky top-0 bg-bg/90 backdrop-blur-md z-20 pt-6 pb-6">
        <button 
           onClick={handleBack} 
           className="w-10 h-10 flex items-center justify-center rounded-full bg-white border border-border/50 hover:bg-gray-50 active:scale-95 transition-all text-ink shadow-sm"
        >
           <ArrowLeft size={20} />
        </button>
      </div>
      <div className="flex-1 flex flex-col max-w-lg mx-auto w-full mt-2">
        <div className="w-16 h-16 bg-primary-soft rounded-3xl flex items-center justify-center text-primary mb-8 shadow-soft">
           <User size={32} />
        </div>
        <div className="space-y-4 mb-10">
          <h1 className="text-[22px] sm:text-[26px] md:text-[30px] font-black leading-[1.1] tracking-tight text-ink">
            {t.authTitle}
          </h1>
          <p className="text-[17px] font-semibold text-ink-soft leading-relaxed max-w-[300px]">
            {t.authDesc}
          </p>
        </div>

        <div className="space-y-4 w-full">
          <button 
            onClick={() => { setProfile(p => ({ ...p, authProvider: 'google', name: 'Jean Dupont' })); setStep(6); }}
            className="w-full flex items-center justify-center gap-3 p-4 rounded-xl bg-white border border-border/60 shadow-soft hover:shadow-mid transition-all active:scale-95 text-lg font-bold text-ink"
          >
            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
               <path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" fill="#4285F4"/>
               <path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" fill="#34A853"/>
               <path d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z" fill="#FBBC05"/>
               <path d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" fill="#EA4335"/>
            </svg>
            {t.btnGoogle}
          </button>
          
          <button 
             onClick={() => { setProfile(p => ({ ...p, authProvider: 'apple', name: 'Marie Bella' })); setStep(6); }}
            className="w-full flex items-center justify-center gap-3 p-4 rounded-xl bg-ink text-white font-bold shadow-[0_8px_20px_rgba(15,23,42,0.2)] hover:bg-black transition-all active:scale-95 text-lg"
          >
            <svg width="24" height="24" viewBox="0 0 24 24" fill="currentColor">
              <path d="M17.05 11.46c-.03-2.06 1.66-3.05 1.74-3.1-1.02-1.49-2.62-1.71-3.19-1.74-1.36-.14-2.65.8-3.35.8-.7 0-1.77-.78-2.89-.76-1.45.02-2.79.84-3.54 2.17-1.52 2.65-.39 6.57 1.1 8.74.73 1.05 1.58 2.22 2.7 2.18 1.08-.05 1.49-.71 2.8-.71 1.29 0 1.68.71 2.81.69 1.16-.02 1.91-1.07 2.62-2.13.82-1.2 1.16-2.36 1.18-2.42-.03-.01-2.24-.86-2.27-3.41h.29zm-2.08-4.23c.61-.74 1.02-1.77.9-2.8-.88.04-1.96.6-2.58 1.34-.55.65-.99 1.69-.87 2.68.99.08 1.95-.49 2.55-1.22z"/>
            </svg>
            {t.btnApple}
          </button>

          <div className="relative flex items-center py-5">
             <div className="flex-grow border-t border-border"></div>
             <span className="flex-shrink-0 mx-4 text-ink-soft text-sm font-extrabold uppercase tracking-widest">{isEN ? 'Or' : 'Ou'}</span>
             <div className="flex-grow border-t border-border"></div>
          </div>

          <button 
            onClick={() => { setProfile(p => ({ ...p, authProvider: 'guest' })); onComplete(profile as UserProfile); }}
            className="w-full flex items-center justify-center p-4 rounded-xl bg-bg border border-border font-bold text-ink-soft shadow-sm hover:bg-gray-100 transition-all active:scale-95 text-lg"
          >
            {t.btnGuest}
          </button>
        </div>
      </div>
    </div>,

    // ------------------------------------
    // STEP 6: Identity (Name)
    // ------------------------------------
    <div key="step-6" className="flex flex-col flex-1 bg-bg px-6 pt-6 pb-48 relative">
      <div className="-mx-6 px-6 sticky top-0 bg-bg z-20 pt-4 pb-4 mb-2">
         <h1 className="text-[22px] sm:text-[26px] font-black leading-[1.1] tracking-tight text-ink max-w-lg mx-auto">
           {t.nameTitle}
         </h1>
      </div>
      <div className="flex-1 flex flex-col max-w-lg mx-auto w-full pb-32">
         <p className="text-[17px] font-semibold text-ink-soft leading-relaxed mb-6">
           {t.nameDesc}
         </p>
         <div className="space-y-5 w-full">
           <div className="flex flex-col gap-2">
             <label className="text-[15px] font-extrabold text-ink-soft ml-1">{isEN ? 'Your full name' : 'Ton nom complet'}</label>
             <input 
               autoFocus
               type="text" 
               value={profile.name || ''}
               onChange={(e) => setProfile(p => ({ ...p, name: e.target.value }))}
               className="w-full px-5 py-4 bg-white rounded-2xl text-ink font-bold shadow-[0_4px_20px_rgba(15,23,42,0.04)] outline-none focus:ring-2 focus:ring-primary transition-all text-[17px]"
               placeholder={t.namePlaceholder}
             />
           </div>
         </div>
      </div>
    </div>,

    // ------------------------------------
    // STEP 7: Identity (Phone)
    // ------------------------------------
    <div key="step-7" className="flex flex-col flex-1 bg-bg px-6 pt-6 pb-48 relative">
      <div className="-mx-6 px-6 sticky top-0 bg-bg z-20 pt-4 pb-4 mb-2">
         <h1 className="text-[22px] sm:text-[26px] font-black leading-[1.1] tracking-tight text-ink max-w-lg mx-auto">
           {t.phoneTitle}
         </h1>
      </div>
      <div className="flex-1 flex flex-col max-w-lg mx-auto w-full pb-32">
         <p className="text-[17px] font-semibold text-ink-soft leading-relaxed mb-6">
           {t.phoneDesc}
         </p>
         <div className="space-y-5 w-full">
           <div className="flex flex-col gap-2">
             <label className="text-[15px] font-extrabold text-ink-soft ml-1">{isEN ? 'Phone number' : 'Numéro de téléphone'}</label>
             <div className="relative">
               <div className="absolute left-4 top-[17px] flex items-center gap-2 pointer-events-none">
                 <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 300 200" className="w-5 h-3.5 rounded-sm overflow-hidden bg-white shrink-0">
                   <rect width="100" height="200" fill="#007a5e"/>
                   <rect x="100" width="100" height="200" fill="#ce1126"/>
                   <rect x="200" width="100" height="200" fill="#fcd116"/>
                   <polygon fill="#fcd116" points="150,60 155,85 180,85 160,100 167,125 150,110 133,125 140,100 120,85 145,85"/>
                 </svg>
                 <span className="font-bold text-ink border-r border-border/80 pr-2">+237</span>
               </div>
               <input 
                 type="tel" 
                 value={profile.phone || ''}
                 onChange={(e) => setProfile(p => ({ ...p, phone: e.target.value }))}
                 className="w-full pl-[95px] pr-5 py-4 bg-white rounded-2xl text-ink font-bold shadow-[0_4px_20px_rgba(15,23,42,0.04)] outline-none focus:ring-2 focus:ring-primary transition-all text-[17px]"
                 placeholder="6 -- -- -- --"
               />
             </div>
           </div>
         </div>
      </div>
    </div>,

    // ------------------------------------
    // STEP 8: School (Optional)
    // ------------------------------------
    <div key="step-8" className="flex flex-col flex-1 px-6 pb-48 relative">
      <div className="-mx-6 px-6 sticky top-0 bg-bg z-20 pt-4 pb-4 mb-4 text-center">
        <h2 className="text-[22px] sm:text-[26px] font-black text-ink tracking-tight leading-[1.1] max-w-lg mx-auto">
          {t.schoolTitle}
        </h2>
        <p className="text-ink-soft text-[16px] font-semibold px-4 mt-3 max-w-lg mx-auto">
          {t.schoolDesc}
        </p>
      </div>
      
      <div className="max-w-lg mx-auto w-full pb-32">
         <div className="relative mb-8">
           <Search className="absolute left-5 top-[20px] text-muted" size={22} />
           <input 
             type="text" 
             value={searchSchool}
             onChange={(e) => { setSearchSchool(e.target.value); setProfile(p => ({ ...p, school: undefined })); }}
             className="w-full pl-14 pr-12 py-5 bg-white rounded-2xl text-ink font-bold shadow-[0_8px_30px_rgba(15,23,42,0.06)] focus:ring-2 focus:ring-primary focus:outline-none transition-all text-[17px]"
             placeholder={t.schoolPlaceholder}
           />
           {searchSchool && (
             <button 
               onClick={() => {setSearchSchool(''); setProfile(p => ({ ...p, school: undefined }));}} 
               className="absolute right-5 top-[20px] text-mute-2 hover:text-ink transition-colors"
             >
               <XCircle size={22} />
             </button>
           )}
         </div>
         <div className="space-y-4">
            {filteredSchools.map(s => (
              <SelectionCard 
                key={s}
                selected={profile.school === s}
                onClick={() => { setProfile(p => ({ ...p, school: s })); setSearchSchool(s); }}
                title={s}
                icon={null}
              />
            ))}
            {searchSchool && filteredSchools.length === 0 && profile.school !== searchSchool && (
              <button 
                 onClick={() => {
                   setProfile(p => ({ ...p, school: searchSchool }));
                   showToast(t.schoolToast);
                 }}
                 className="w-full p-5 rounded-[20px] text-left border-dashed border-2 border-primary/50 bg-primary-soft text-primary font-bold flex items-center justify-between hover:bg-primary-light transition-colors"
              >
                 <span className="text-[17px]">{t.schoolAdd} "{searchSchool}"</span>
                 <Plus size={20} />
              </button>
            )}
         </div>
      </div>
    </div>,

    // ------------------------------------
    // STEP 9: Massive Celebration Success
    // ------------------------------------
    <div key="step-9" className="flex flex-col h-full items-center justify-center px-6 text-center pb-20 relative bg-bg overflow-hidden">
      <canvas ref={canvasRef} className="absolute inset-0 w-full h-full pointer-events-none z-0" />
      <motion.div 
         initial={{ scale: 0, opacity: 0 }}
         animate={{ scale: 1, opacity: 1 }}
         transition={{ type: 'spring', damping: 15, stiffness: 200, delay: 0.1 }}
         className="w-32 h-32 bg-success-soft rounded-full flex items-center justify-center text-success mb-8 shadow-[0_0_60px_rgba(22,163,74,0.3)] relative"
      >
         <motion.div animate={{ y: [0, -20, 0], opacity: [1, 0, 1] }} transition={{ repeat: Infinity, duration: 2 }} className="absolute -top-4 -left-2 text-warning"><PartyPopper size={28} /></motion.div>
         <motion.div animate={{ y: [0, 20, 0], opacity: [1, 0, 1] }} transition={{ repeat: Infinity, duration: 2.2 }} className="absolute -bottom-2 -right-4 text-primary"><Sparkles size={28} /></motion.div>
         <motion.div animate={{ x: [0, 20, 0] }} transition={{ repeat: Infinity, duration: 1.8 }} className="absolute top-8 -right-6 text-sky"><CheckCircle2 size={24} /></motion.div>
         
         <Check size={64} strokeWidth={3} />
      </motion.div>
      
      <motion.h2 
         initial={{ y: 20, opacity: 0 }}
         animate={{ y: 0, opacity: 1 }}
         transition={{ delay: 0.3, duration: 0.4 }}
         className="text-[22px] sm:text-[26px] font-black text-ink tracking-tight leading-tight mb-4 w-full"
      >
        {t.successTitle}
      </motion.h2>
      
      <motion.p 
         initial={{ y: 20, opacity: 0 }}
         animate={{ y: 0, opacity: 1 }}
         transition={{ delay: 0.4, duration: 0.4 }}
         className="text-[17px] font-semibold text-ink-soft max-w-[280px]"
      >
        {t.successDesc}
      </motion.p>
    </div>,
  ];

  function renderSerieItem(serie: any) {
    const isSelected = profile.serieId === serie.id;
    const IconComp = getSubjectIcon(serie.name);
    return (
       <SelectionCard 
          key={serie.id}
          selected={isSelected}
          onClick={() => setProfile(p => ({ ...p, serieId: serie.id }))}
          title={serie.name}
          desc={serie.desc}
          icon={<IconComp size={20} />}
       />
    );
  }

  let currentCta = t.btnNext;
  if (step === 1) currentCta = t.introNext;
  if (step === 4) currentCta = t.btnValidate;
  if (step === 7) currentCta = t.btnValidate;
  if (step === 8) currentCta = t.schoolConfirm;
  if (step === 9) currentCta = t.btnStart;

  const showFooterCta = step !== 5;

  return (
    <div className="flex flex-col flex-1 w-full bg-bg relative overflow-hidden">
      
      <AnimatePresence>
        {toast && (
          <motion.div 
            initial={{ y: -60, opacity: 0 }} 
            animate={{ y: 0, opacity: 1 }} 
            exit={{ y: -60, opacity: 0 }} 
            className="absolute top-4 left-4 right-4 bg-primary text-white p-4 rounded-2xl shadow-[0_8px_30px_rgba(37,99,235,0.3)] z-50 flex items-center gap-3 max-w-lg mx-auto"
          >
            <CheckCircle2 size={24} className="text-white" />
            <span className="font-bold text-[15px]">{toast}</span>
          </motion.div>
        )}
      </AnimatePresence>

      {/* HEADER PROGRESS (Fixed Top) */}
      {configStepsActive && (
        <div className="flex-none z-40 px-4 py-4 pt-6 flex flex-col bg-bg border-b border-border/50 relative shadow-sm">
          <div className="flex items-center gap-4 max-w-lg mx-auto w-full">
            <button 
               onClick={handleBack} 
               className="p-3 rounded-full bg-white/50 hover:bg-white active:scale-95 text-ink transition-colors shadow-soft shrink-0"
            >
               <ArrowLeft size={20} />
            </button>
            <div className="flex-1 h-3 bg-white shadow-inner rounded-full overflow-hidden">
              <div 
                 className="h-full bg-primary transition-all duration-500 ease-out rounded-full" 
                 style={{ width: `${progress}%` }}
              ></div>
            </div>
            <div className="font-bold text-ink-soft text-[14px]">
               {step <= 4 ? step - 1 : step - 5}/3
            </div>
          </div>
        </div>
      )}

      {/* COMPONENT RENDERER */}
      <div className="flex-1 overflow-y-auto w-full relative">
        <AnimatePresence mode="popLayout" custom={step}>
          <motion.div
            key={step}
            initial={{ opacity: 0, x: 20 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: -20 }}
            transition={{ duration: 0.3, ease: 'easeOut' }}
            className="w-full min-h-full flex flex-col"
          >
            {stepsContent[step]}
          </motion.div>
        </AnimatePresence>
      </div>

      {/* FIXED FOOTER CTA (Overlay) */}
      {showFooterCta && (
        <div className="absolute bottom-0 inset-x-0 p-5 pt-20 bg-gradient-to-t from-bg via-bg/95 to-transparent pointer-events-none z-40">
          <div className="max-w-lg mx-auto w-full pointer-events-auto">
             <button 
               onClick={step === 9 ? () => onComplete(profile as UserProfile) : handleNext} 
               disabled={isNextDisabled()} 
               className={step === 9 ? `${btnClasses} bg-success text-white shadow-[0_8px_20px_rgba(22,163,74,0.25)] active:scale-95 text-[18px]` : primaryBtn}
             >
               {currentCta}
             </button>
          </div>
        </div>
      )}

    </div>
  );
}

function SelectionCard({ selected, onClick, title, desc, icon, compact = false }: any) {
  return (
    <button 
      onClick={onClick}
      className={`w-full ${compact ? 'p-3' : 'p-4 md:p-5'} rounded-2xl flex items-center gap-3 transition-all text-left shadow-soft
        ${selected ? 'bg-primary-soft ring-2 ring-primary border border-transparent scale-[1.01] shadow-[0_10px_30px_rgba(37,99,235,0.15)] z-10 relative' : 'bg-white border border-border/50 hover:bg-gray-50 hover:border-border'}
      `}
    >
      {icon && (
         <div className={`${compact ? 'w-10 h-10 rounded-xl' : 'w-12 h-12 rounded-2xl'} shrink-0 flex items-center justify-center transition-colors ${selected ? 'bg-primary text-white shadow-brand' : 'bg-bg text-ink-soft'}`}>
           {icon}
         </div>
      )}
      <div className="flex-1">
        <p className={`font-black ${compact ? 'text-[15px]' : 'text-[17px]'} ${selected ? 'text-primary' : 'text-ink'}`}>{title}</p>
        {desc && <p className={`text-[12px] font-semibold mt-[2px] leading-snug ${selected ? 'text-primary-dark opacity-80' : 'text-ink-soft'}`}>{desc}</p>}
      </div>
      {selected ? (
         <div className={`shrink-0 ${compact ? 'w-5 h-5' : 'w-6 h-6'} rounded-full bg-primary text-white flex items-center justify-center`}>
            <Check size={compact ? 12 : 14} strokeWidth={3} />
         </div>
      ) : (
         <div className={`shrink-0 ${compact ? 'w-5 h-5' : 'w-6 h-6'} rounded-full border-2 border-border/50`} />
      )}
    </button>
  );
}
