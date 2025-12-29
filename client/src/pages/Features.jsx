import React from 'react';
import Navbar from '../components/Navbar';
import useCms from '../hooks/useCms';
import { CheckCircle } from 'lucide-react';

const Features = () => {
    const { cmsContent } = useCms();

    // Default features if CMS is empty
    const defaultFeatures = [
        { title: 'Smart POS', desc: 'Fast and intuitive point of sale.' },
        { title: 'Inventory Management', desc: 'Real-time tracking of your stock.' },
        { title: 'Financial Reports', desc: 'Deep insights into your profit and loss.' },
    ];

    const features = (cmsContent.CMS_FEATURES_LIST && cmsContent.CMS_FEATURES_LIST.length > 0)
        ? cmsContent.CMS_FEATURES_LIST
        : defaultFeatures;

    return (
        <div className="min-h-screen bg-gradient-to-b from-[#0a0b0f] via-[#0b1020] to-[#0a0b0f] font-sans text-slate-200">
            <Navbar />
            <div className="pt-32 pb-20 px-4 max-w-7xl mx-auto">
                <div className="text-center mb-20">
                    <h1 className="text-4xl md:text-6xl font-bold text-white mb-6">Fitur Kuat</h1>
                    <p className="text-xl text-slate-300 max-w-2xl mx-auto">Semua yang Anda butuhkan untuk menjalankan bisnis, dalam satu tempat.</p>
                </div>

                <div className="grid md:grid-cols-3 gap-8">
                    {features.map((feature, idx) => (
                        <div key={idx} className="bg-white/5 border border-white/10 p-8 rounded-3xl hover:-translate-y-2 transition-all duration-300">
                            <div className="w-16 h-16 rounded-full bg-white/10 border border-white/10 flex items-center justify-center text-indigo-400 mb-6 mx-auto">
                                <CheckCircle size={32} />
                            </div>
                            <h3 className="text-2xl font-bold text-white mb-4 text-center">{feature.title}</h3>
                            <p className="text-slate-300 text-center leading-relaxed">
                                {feature.desc}
                            </p>
                        </div>
                    ))}
                </div>
            </div>
        </div>
    );
};

export default Features;
