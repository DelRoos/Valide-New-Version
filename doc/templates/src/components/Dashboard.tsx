import { UserProfile } from '../types';
import { 
  FR_LEVELS, EN_LEVELS, EN_TECH_LEVELS,
  FR_SERIES_2NDE, FR_SERIES_CYCLE_TERMINAL, FR_TECH_SERIES, EN_TECH_SERIES,
  EN_O_LEVEL_SUBJECTS, EN_A_LEVEL_SUBJECTS
} from '../data/educationData';
import { Bell, User, BookOpen, Clock, Target, LogOut, CheckCircle2, MapPin } from 'lucide-react';

export default function Dashboard({ profile, onSignOut }: { profile: UserProfile, onSignOut: () => void }) {
  const isFR = profile.subSystem === 'francophone';
  const isTech = profile.track === 'technique';
  const isEN = !isFR;
  
  const vocabulary = {
    greeting: isEN ? 'Hi there, Champion' : 'Salut, l\'artiste',
    trackLabel: isEN ? (isTech ? 'Technical' : 'General') : (isTech ? 'Technique' : 'Général'),
    systemLabel: isEN ? 'Anglophone' : 'Francophone',
    targetLabel: isEN ? 'GCE 2026' : 'BAC 2026',
    mySubjects: isEN ? 'My Key Subjects' : 'Mes matières phares',
    viewAll: isEN ? 'View all' : 'Voir tout',
    upcoming: isEN ? 'Upcoming Exams' : 'Ça arrive vite',
    evalDesc: isEN ? 'First Term Evaluation' : 'Évaluation Séquence 3',
    logout: isEN ? 'Log out (Reset)' : 'Se déconnecter (Reset)',
    schoolDefault: isEN ? 'My School' : 'Mon école'
  };

  const levelRef = isFR ? FR_LEVELS.find(l => l.id === profile.levelId) : 
     (isTech ? EN_TECH_LEVELS.find(l => l.id === profile.levelId) : EN_LEVELS.find(l => l.id === profile.levelId));
  
  let serieRef = null;
  if (isFR && profile.serieId) {
    if (isTech) {
      serieRef = FR_TECH_SERIES.find(s => s.id === profile.serieId);
    } else {
      serieRef = [...FR_SERIES_2NDE, ...FR_SERIES_CYCLE_TERMINAL].find(s => s.id === profile.serieId);
    }
  } else if (!isFR && isTech && profile.serieId) {
    serieRef = EN_TECH_SERIES.find(s => s.id === profile.serieId);
  }

  // Generate fake subjects based on series if Francophone
  const frSubjectsDisplay = isFR ? [
    { name: isTech ? 'Travaux Pratiques' : 'Mathématiques', coef: profile.serieId === 'c' || profile.serieId === '2nde_c' ? 7 : 4, theme: 'sky' },
    { name: isTech ? 'Mathématiques Appliquées' : 'Physique-Chimie', coef: profile.serieId === 'c' ? 5 : profile.serieId === 'd' ? 4 : 3, theme: 'warning' },
    { name: 'Français', coef: profile.serieId === 'a4' || profile.serieId === '2nde_a' ? 5 : 2, theme: 'danger' },
  ] : [];

  // Get selected EN subjects
  const angloSubjectsDisplay = (!isFR && !isTech && profile.subjectIds) ? 
    [...(profile.levelId === 'form5' ? EN_O_LEVEL_SUBJECTS : EN_A_LEVEL_SUBJECTS)]
      .filter(s => s.mandatory || profile.subjectIds!.includes(s.id))
  : [];

  const techENSubjectsDisplay = (!isFR && isTech) ? [
     { name: 'Professional Practice', theme: 'sky' },
     { name: 'Related Mathematics', theme: 'warning' },
     { name: 'English Language', theme: 'danger' },
  ] : [];

  return (
    <div className="flex-1 w-full bg-[#f1f5f9] flex flex-col relative">
      {/* Header Profile */}
      <div className="bg-primary px-6 pt-10 pb-16 rounded-b-[32px] shadow-mid relative z-10">
        <div className="flex justify-between items-center mb-6">
          <div className="flex items-center gap-3">
             <div className="w-12 h-12 bg-white/20 backdrop-blur-md rounded-full flex items-center justify-center text-white">
                <User size={24} />
             </div>
             <div>
               <p className="text-primary-light text-[12px] font-bold uppercase tracking-wider">{vocabulary.greeting}</p>
               <p className="text-white text-[20px] font-extrabold tracking-tight">{profile.name}</p>
             </div>
          </div>
          <button className="w-10 h-10 bg-white/10 rounded-full flex items-center justify-center text-white relative hover:bg-white/20 transition-colors">
            <Bell size={20} />
            <span className="absolute top-2 right-2 w-2.5 h-2.5 bg-warning rounded-full border-2 border-primary"></span>
          </button>
        </div>

        <div className="bg-white rounded-2xl p-5 shadow-soft absolute -bottom-14 left-6 right-6 border border-border">
           <div className="flex items-center gap-2 mb-2">
              <span className="text-[10px] font-extrabold text-muted uppercase tracking-wider bg-bg px-2 py-0.5 rounded">
                {vocabulary.systemLabel} &middot; {vocabulary.trackLabel}
              </span>
           </div>
           <div className="flex items-end justify-between">
              <div>
                <h2 className="text-[20px] font-black text-ink pb-0.5 leading-tight">
                  {levelRef?.label} 
                </h2>
                {serieRef && <p className="text-[14px] font-bold text-primary">{serieRef.name}</p>}
                
                <div className="flex items-center gap-1.5 mt-2.5 text-ink-soft text-[13px] font-bold">
                  <MapPin size={14} className="text-muted" />
                  <span className="truncate max-w-[200px]">{profile.school || vocabulary.schoolDefault}</span>
                </div>
              </div>
              <div className="flex bg-primary-soft text-primary px-3 py-1.5 rounded-lg text-sm font-bold items-center gap-1.5 h-fit">
                <Target size={16} /> {vocabulary.targetLabel}
              </div>
           </div>
        </div>
      </div>

      <div className="flex-1 overflow-y-auto pt-24 px-6 pb-24">
         
         <div className="mb-6 flex items-center justify-between">
            <h3 className="text-[18px] font-extrabold text-ink">{vocabulary.mySubjects}</h3>
            <span className="text-[13px] font-bold text-primary cursor-pointer hover:underline">{vocabulary.viewAll}</span>
         </div>

         <div className="grid gap-3">
           {isFR ? (
             frSubjectsDisplay.map((subj, idx) => (
               <div key={idx} className="bg-white p-4 rounded-xl shadow-soft border border-border flex items-center justify-between">
                  <div className="flex items-center gap-4">
                     <div className={`w-12 h-12 rounded-xl flex items-center justify-center bg-${subj.theme}-soft text-${subj.theme}-ink`}>
                       <BookOpen size={22} />
                     </div>
                     <div>
                        <p className="font-bold text-ink text-[16px]">{subj.name}</p>
                        <p className="text-[13px] font-semibold text-muted">Coef. {subj.coef}</p>
                     </div>
                  </div>
                  <div className="text-right">
                     <p className="text-[13px] font-mono font-bold text-ink-soft">--/20</p>
                  </div>
               </div>
             ))
           ) : isTech ? (
             techENSubjectsDisplay.map((subj, idx) => (
               <div key={idx} className="bg-white p-4 rounded-xl shadow-soft border border-border flex items-center gap-4">
                  <div className={`w-12 h-12 rounded-xl flex items-center justify-center bg-${subj.theme}-soft text-${subj.theme}-ink`}>
                    <BookOpen size={22} />
                  </div>
                  <div>
                     <p className="font-bold text-ink text-[16px]">{subj.name}</p>
                     <p className="text-[11px] font-extrabold text-mute-2 uppercase tracking-wider mt-0.5">TVEE Core</p>
                  </div>
               </div>
             ))
           ) : (
             angloSubjectsDisplay.map((subj, idx) => (
               <div key={idx} className="bg-white p-4 rounded-xl shadow-soft border border-border flex items-center justify-between">
                  <div className="flex items-center gap-4">
                    <div className="w-12 h-12 rounded-xl flex items-center justify-center bg-primary-soft text-primary">
                      <CheckCircle2 size={22} />
                    </div>
                    <div>
                      <p className="font-bold text-ink text-[16px]">{subj.name}</p>
                      {subj.mandatory && <span className="text-[10px] font-extrabold text-warning-ink bg-warning-soft px-2 py-0.5 rounded uppercase tracking-wider inline-block mt-0.5">Core</span>}
                    </div>
                  </div>
               </div>
             ))
           )}
         </div>

         <h3 className="text-[18px] font-extrabold text-ink mt-8 mb-4">{vocabulary.upcoming}</h3>
         <div className="bg-ink p-5 rounded-2xl shadow-mid text-white flex gap-4">
            <div className="w-14 h-14 bg-white/10 rounded-xl flex flex-col items-center justify-center">
               <span className="text-[12px] font-bold text-mute-2 uppercase">{isEN ? 'THU' : 'JEU'}</span>
               <span className="text-[20px] font-extrabold font-mono">14</span>
            </div>
            <div className="flex-1 flex flex-col justify-center">
               <p className="font-extrabold text-[16px]">{vocabulary.evalDesc}</p>
               <p className="text-[13px] font-medium text-mute-2 flex items-center gap-1.5 mt-1">
                 <Clock size={14} /> 08:00 - {isEN ? 'Room R12' : 'Salle R12'}
               </p>
            </div>
         </div>

         <div className="mt-8 mb-6">
            <button onClick={onSignOut} className="w-full flex items-center justify-center gap-2 p-4 rounded-xl font-bold bg-danger-soft text-danger-ink hover:bg-danger hover:text-white transition-all active:scale-95 border border-danger/20">
               <LogOut size={18} /> {vocabulary.logout}
            </button>
         </div>

      </div>
    </div>
  );
}
