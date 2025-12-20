import React from 'react';

const Card = ({ children, className = '' }) => {
    return (
        <div className={`bg-white rounded-xl border border-slate-200 shadow-sm ${className}`}>
            {children}
        </div>
    );
};

export default Card;
