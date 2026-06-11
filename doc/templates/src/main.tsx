import { StrictMode, useState } from 'react';
import { createRoot } from 'react-dom/client';
import { AnimatePresence } from 'motion/react';
import OnboardingFlow from './components/OnboardingFlow';
import Dashboard from './components/Dashboard';
import type { UserProfile } from './types';
import './index.css';

function App() {
  const [profile, setProfile] = useState<UserProfile | null>(null);

  return (
    <div className="flex justify-center items-center min-h-screen bg-slate-800 p-2 sm:p-6 lg:p-12 overflow-hidden">
      {/* 
        Conteneur mobile-first central (frame) 
        Pour rendre l'illusion d'une application mobile dans le navigateur
      */}
      <div 
        className="w-full max-w-[400px] h-[100dvh] md:h-[840px] bg-bg relative flex flex-col shadow-2xl md:rounded-[40px] md:border-[8px] border-black overflow-hidden"
      >
        {/* Dynamic Island / Notch Fake (Desktop only for aesthetics) */}
        <div className="hidden md:block absolute top-0 inset-x-0 h-6 bg-black z-50 rounded-b-2xl w-[140px] mx-auto"></div>
        
        <AnimatePresence mode="wait">
          {!profile ? (
            <OnboardingFlow key="onboarding" onComplete={setProfile} />
          ) : (
            <Dashboard key="dashboard" profile={profile} onSignOut={() => setProfile(null)} />
          )}
        </AnimatePresence>
      </div>
    </div>
  );
}

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <App />
  </StrictMode>,
);
