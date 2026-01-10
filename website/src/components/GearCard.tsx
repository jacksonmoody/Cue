"use client";

import { motion } from "motion/react";
import { LucideIcon } from "lucide-react";

interface GearCardProps {
  title: string;
  description: string;
  Icon: LucideIcon;
  step: number;
}

export default function GearCard({
  title,
  description,
  Icon,
  step,
}: GearCardProps) {
  return (
    <motion.div
      initial={{ opacity: 0 }}
      whileInView={{ opacity: 1 }}
      viewport={{ once: true }}
      transition={{ duration: 0.4, delay: step * 0.4, ease: "easeInOut" }}
      className="bg-white/10 backdrop-blur-lg border border-white/20 p-8 rounded-2xl shadow-xl flex flex-col items-center text-center relative overflow-hidden hover:border-primary transition-all duration-300"
    >
      <div className="absolute top-0 right-0 p-4 opacity-10 font-black text-6xl text-white">
        {step}
      </div>

      <div className="mb-6 p-4 bg-primary rounded-full shadow-lg">
        <Icon size={40} className="text-white" />
      </div>

      <h3 className="text-xl font-bold mb-3 text-white">{title}</h3>
      <p className="text-blue-100">{description}</p>
    </motion.div>
  );
}
