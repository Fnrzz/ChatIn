import Image from "next/image";
import { ArrowUpRight, Star } from "lucide-react";

export function Hero() {
  return (
    <section
      className="relative w-full h-screen flex flex-col font-sans text-black overflow-hidden"
      style={{
        backgroundImage: 'url("/background/background-hero.avif")',
        backgroundSize: "cover",
        backgroundPosition: "center",
        backgroundRepeat: "no-repeat",
      }}
    >
      {/* Background Overlay */}
      <div className="absolute inset-0 bg-black/40 backdrop-blur-[2px] z-0"></div>

      <div className="relative z-10 flex-1 flex flex-col lg:flex-row max-w-7xl mx-auto w-full px-8 pt-24 pb-8 gap-8 lg:gap-12">
        {/* Left Text Content */}
        <div className="flex-1 flex flex-col gap-6 justify-start pt-0 lg:pt-30">
          <h1 className="text-5xl lg:text-6xl font-bold leading-[1.1] tracking-tight text-white">
            Empower Your Chats with Agent-Based AI
          </h1>

          <p className="text-base lg:text-lg max-w-xl leading-relaxed text-white">
            From local transactions to international payments, manage everything
            in one powerful platform.
          </p>

          <div className="flex flex-row flex-wrap items-center gap-4 mt-4 ">
            <button className="flex-1 flex items-center justify-center gap-3 bg-[#0E3524] text-white px-4 px-6 py-2.5 py-3.5 rounded-full font-medium hover:bg-[#0E3524]/90 transition-colors text-xs text-base whitespace-nowrap">
              <span>
                <span>Get 14-days free trial</span>
              </span>
              <span className="bg-white text-black rounded-full p-0.5 p-1 flex-shrink-0">
                <ArrowUpRight className="w-3.5 w-4 h-3.5 h-4" />
              </span>
            </button>

            <button className="flex-1 flex items-center justify-center gap-3 bg-white/20 backdrop-blur-md border border-white/40 px-4 px-6 py-2.5 py-3.5 rounded-full font-medium hover:bg-white/30 transition-colors text-white text-xs text-base whitespace-nowrap">
              <span>
                <span>Download the app</span>
              </span>
              <span className="bg-[#0E3524] text-white rounded-full p-0.5 p-1 flex-shrink-0">
                <ArrowUpRight className="w-3.5 w-4 h-3.5 h-4" />
              </span>
            </button>
          </div>

          <div className="flex items-center justify-center gap-8 mt-12">
            {/* App Store Rating */}
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-lg overflow-hidden shadow-md flex items-center justify-center">
                <Image
                  src="/svg/appstore.svg"
                  alt="App Store"
                  width={40}
                  height={40}
                  className="w-full h-full object-cover"
                />
              </div>
              <div className="text-sm font-medium">
                <div className="flex items-center gap-1">
                  <span className="font-bold text-lg text-white">4.8</span>
                  <Star className="w-4 h-4 fill-yellow-500 text-yellow-500" />
                </div>
                <div className="text-xs opacity-70 text-white">
                  on App Store
                </div>
              </div>
            </div>

            {/* Google Play Rating */}
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-lg overflow-hidden shadow-md flex items-center justify-center bg-white">
                <Image
                  src="/svg/googleplay.svg"
                  alt="Google Play"
                  width={40}
                  height={40}
                  className="w-full h-full object-cover"
                />
              </div>
              <div className="text-sm font-medium">
                <div className="flex items-center gap-1">
                  <span className="font-bold text-lg text-white">4.8</span>
                  <Star className="w-4 h-4 fill-yellow-500 text-yellow-500" />
                </div>
                <div className="text-xs opacity-70 text-white">Google Play</div>
              </div>
            </div>
          </div>
        </div>

        {/* Right Phone Mockup */}
        <div className="flex-1 flex items-end justify-center lg:justify-end relative">
          <Image
            src="/mockup/homepage-new.avif"
            alt="App Interface"
            width={400}
            height={800}
            className="w-full max-w-[450px] h-auto object-contain drop-shadow-2xl"
            priority
          />
        </div>
      </div>
    </section>
  );
}
