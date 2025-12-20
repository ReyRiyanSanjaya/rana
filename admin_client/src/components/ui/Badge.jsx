import React from 'react';

const Badge = ({ children, variant = 'neutral', icon: Icon }) => {
    const variants = {
        neutral: "bg-slate-100 text-slate-700 border-slate-200",
        success: "bg-green-50 text-green-700 border-green-200",
        warning: "bg-yellow-50 text-yellow-700 border-yellow-200",
        error: "bg-red-50 text-red-700 border-red-200",
        brand: "bg-primary-50 text-primary-700 border-primary-200",
    };

    return (
        <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium border ${variants[variant]}`}>
            {Icon && <Icon className="w-3 h-3 mr-1" />}
            {children}
        </span>
    );
};

export default Badge;
