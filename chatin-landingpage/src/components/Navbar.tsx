import Image from "next/image";
import { ArrowUpRight } from "lucide-react";

export function Navbar() {
  return (
    <nav className="fixed top-0 left-0 right-0 z-50 flex items-center justify-between px-8 py-6 max-w-7xl mx-auto w-full">
      <div className="flex items-center gap-2">
        <Image
          src="/app_logo.png"
          alt="ChatIn Logo"
          width={32}
          height={32}
          className="w-8 h-8 object-contain"
        />
        <span className="text-xl font-bold text-white">ChatIn</span>
      </div>

      <div className="hidden md:flex items-center gap-8 font-medium text-sm">
        <a href="#" className="hover:opacity-70 text-white">
          Home
        </a>
        <a href="#" className="hover:opacity-70 text-white">
          Features
        </a>
        <a href="#" className="hover:opacity-70 text-white">
          Pricing
        </a>
        <a href="#" className="hover:opacity-70 text-white">
          About
        </a>
      </div>

      <div className="flex items-center gap-4 text-sm font-medium">
        <a href="#" className="hover:opacity-70 text-white">
          Login
        </a>
        <a
          href="#"
          className="flex items-center text-black gap-2 bg-white/40 backdrop-blur-md border border-white/50 px-4 py-2 rounded-full hover:bg-white/60 transition-colors"
        >
          Sign up
          <span className="bg-white rounded-full p-1 shadow-sm">
            <ArrowUpRight className="w-3 h-3" />
          </span>
        </a>
      </div>
    </nav>
  );
}
