"use client";

import { motion } from "motion/react";
import { ArrowRight, Brain, BrainCircuit, Wind } from "lucide-react";
import GearCard from "../components/GearCard";
import AnimatedSection from "../components/AnimatedSection";
import Image from "next/image";
import Logo from "./logo.png";
import Watch from "./watch.png";
import Link from "next/link";

export default function Home() {
  const scrollToGears = () => {
    document.getElementById("gears")?.scrollIntoView({ behavior: "smooth" });
  };

  const openForm = () => {
    window.open(
      "https://forms.gle/CW8xGCD5WiE7J2cs7",
      "_blank",
      "noopener,noreferrer"
    );
  };

  return (
    <main className="min-h-screen text-white selection:bg-[#96d8ef] selection:text-[#0f172a] relative overflow-hidden">
      <div className="absolute top-[-10%] left-[-10%] w-[500px] h-[500px] rounded-full bg-[#5499F7] opacity-20 blur-[100px] animate-pulse pointer-events-none" />
      <div className="absolute top-[20%] right-[-10%] w-[400px] h-[400px] rounded-full bg-[#9EB0FF] opacity-20 blur-[100px] animate-pulse pointer-events-none" />
      <div className="absolute top-[50%] left-[-20%] w-[400px] h-[400px] rounded-full bg-[#5499F7] opacity-20 blur-[100px] animate-pulse pointer-events-none" />
      <div className="absolute top-[70%] right-[-20%] w-[400px] h-[400px] rounded-full bg-[#9EB0FF] opacity-20 blur-[100px] animate-pulse pointer-events-none" />
      <div className="absolute bottom-[-10%] left-[-10%] w-[500px] h-[500px] rounded-full bg-[#5499F7] opacity-20 blur-[100px] animate-pulse pointer-events-none" />

      <section className="relative min-h-screen flex flex-col items-center justify-center overflow-hidden px-4">
        <div className="container mx-auto text-center z-10 max-w-4xl">
          <motion.div
            initial={{ opacity: 0, y: 30 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.8 }}
          >
            <div className="flex justify-center items-center mb-6">
              <Image src={Logo} alt="Cue Logo" width={100} height={100} />
            </div>
            <h1 className="text-5xl md:text-7xl font-bold mb-6 tracking-tight">
              Micro-reflections, <br />
              <span className="text-gradient">right on your wrist.</span>
            </h1>
            <p className="text-xl text-blue-100 mb-10 max-w-2xl mx-auto leading-relaxed">
              Cue helps regulate emotions in real-time using a framework
              grounded in psychological theory. Pause, reflect, and reset
              without disrupting your flow.
            </p>

            <div className="flex flex-col sm:flex-row gap-4 justify-center items-center">
              <motion.button
                whileHover={{ scale: 1.05 }}
                whileTap={{ scale: 0.95 }}
                className="px-8 py-4 bg-primary rounded-full font-bold text-black shadow-lg flex items-center gap-2 hover:brightness-110 transition-all cursor-pointer"
                onClick={openForm}
              >
                Get Started <ArrowRight size={20} />
              </motion.button>
              <motion.button
                whileHover={{
                  scale: 1.05,
                  backgroundColor: "rgba(255,255,255,0.1)",
                }}
                whileTap={{ scale: 0.95 }}
                onClick={scrollToGears}
                className="px-8 py-4 bg-transparent border border-white/20 rounded-full font-bold text-white hover:bg-white/10 transition-all cursor-pointer hover:text-primary hover:border-primary"
              >
                How it Works
              </motion.button>
            </div>
          </motion.div>
        </div>
      </section>

      <section id="gears" className="py-24 px-4 relative">
        <div className="container mx-auto">
          <AnimatedSection className="text-center mb-16">
            <h2 className="text-3xl md:text-5xl font-bold mb-6">
              The 3 Gears Approach
            </h2>
            <p className="text-xl text-blue-200 max-w-2xl mx-auto">
              A framework grounded in psychological theory to interrupt habit
              loops and foster greater emotional regulation.
            </p>
          </AnimatedSection>

          <div className="grid md:grid-cols-3 gap-8 max-w-6xl mx-auto">
            <GearCard
              step={1}
              title="Awareness"
              description="Identify the habit loop and become aware of its triggers."
              Icon={Brain}
            />
            <GearCard
              step={2}
              title="Disillusionment"
              description="Shift attention to the body. Foster disillusionment with the old reward."
              Icon={BrainCircuit}
            />
            <GearCard
              step={3}
              title="Substitution"
              description="Substitute a better reward. Use breathing exercises to restore balance and calm."
              Icon={Wind}
            />
          </div>
        </div>
      </section>

      <section className="py-12 relative overflow-hidden">
        <div className="container mx-auto px-4">
          <AnimatedSection className="grid md:grid-cols-2 gap-12 items-center">
            <div className="order-2 md:order-1">
              <h3 className="text-3xl md:text-4xl font-bold mb-4">
                Apple Watch Integration
              </h3>
              <p className="text-lg text-blue-100 mb-6">
                Cue lives on your wrist, ready when you need it. Smart
                notifications prompt you to reflect without pulling out your
                phone or opening an app.
              </p>
              <ul className="space-y-4">
                {[
                  "Smart reminders based on your physiological state",
                  "Quick, 60 second reflection exercises",
                  "Personalized prompts based on your background",
                ].map((item, i) => (
                  <li key={i} className="flex items-center gap-3">
                    <div className="w-6 h-6 rounded-full bg-[#96d8ef] flex items-center justify-center text-[#0f172a]">
                      <ArrowRight size={14} />
                    </div>
                    {item}
                  </li>
                ))}
              </ul>
            </div>
            <div className="order-1 md:order-2 flex justify-center">
              <div className="w-64 h-64 md:w-80 md:h-80 bg-black rounded-3xl hover:rotate-3 flex items-center justify-center relative group hover:border-primary border-black border-2 transition-all duration-300">
                <Image src={Watch} alt="Watch" width={180} height={180} />
              </div>
            </div>
          </AnimatedSection>
        </div>
      </section>

      <section className="px-4 relative overflow-hidden">
        <div className="container mx-auto relative z-10 text-center">
          <AnimatedSection>
            <h2 className="text-4xl md:text-6xl font-bold mb-8 mt-24">
              Ready to Cue in?
            </h2>
            <p className="text-xl text-blue-200 mb-10 max-w-2xl mx-auto">
              Join the experiment and start your journey toward greater
              emotional regulation today.
            </p>
            <motion.button
              whileHover={{ scale: 1.05 }}
              whileTap={{ scale: 0.95 }}
              className="px-10 py-5 bg-white text-[#0f172a] rounded-full font-bold text-lg shadow-xl hover:shadow-2xl hover:bg-blue-50 transition-all cursor-pointer"
              onClick={openForm}
            >
              Join the Experiment
            </motion.button>
            <div className="flex gap-4 justify-center items-center mt-16 mb-12">
              <Link href="/privacy" className="link">
                <p>Privacy Policy</p>
              </Link>
              <span className="text-white/50">|</span>
              <Link href="/terms" className="link">
                <p>Terms of Service</p>
              </Link>
            </div>
          </AnimatedSection>
        </div>
      </section>
    </main>
  );
}
