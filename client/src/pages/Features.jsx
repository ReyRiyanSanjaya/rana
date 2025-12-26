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
        <div className="min-h-screen bg-[#e0e5ec] font-sans text-gray-700">
            <Navbar />
            <div className="pt-32 pb-20 px-4 max-w-7xl mx-auto">
                <div className="text-center mb-20">
                    <h1 className="text-4xl md:text-6xl font-bold text-[#303346] mb-6">Powerful Features</h1>
                    <p className="text-xl text-gray-500 max-w-2xl mx-auto">Everything you need to run your business, all in one place.</p>
                </div>

                <div className="grid md:grid-cols-3 gap-8">
                    {features.map((feature, idx) => (
                        <div key={idx} className="bg-[#e0e5ec] p-8 rounded-3xl shadow-[10px_10px_20px_#bebebe,-10px_-10px_20px_#ffffff] hover:transform hover:-translate-y-2 transition-all duration-300">
                            <div className="w-16 h-16 rounded-full bg-[#e0e5ec] shadow-[inset_5px_5px_10px_#bebebe,inset_-5px_-5px_10px_#ffffff] flex items-center justify-center text-primary mb-6 mx-auto">
                                <CheckCircle size={32} />
                            </div>
                            <h3 className="text-2xl font-bold text-[#303346] mb-4 text-center">{feature.title}</h3>
                            <p className="text-gray-500 text-center leading-relaxed">
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
