import React from 'react';

const Input = ({
    label,
    error,
    helperText,
    className = '',
    ...props
}) => {
    return (
        <div className={`w-full ${className}`}>
            {label && (
                <label className="block text-sm font-medium text-slate-700 mb-1.5">
                    {label}
                </label>
            )}
            <div className="relative">
                <input
                    className={`block w-full rounded-xl border px-3 py-2.5 text-slate-900 shadow-sm outline-none transition-all placeholder:text-slate-400 focus:ring-2 disabled:bg-slate-50 disabled:text-slate-500 ${error
                            ? 'border-red-300 focus:border-red-500 focus:ring-red-100'
                            : 'border-primary-200 hover:border-primary-300 focus:border-primary-500 focus:ring-primary-100'
                        }`}
                    {...props}
                />
            </div>
            {error && <p className="mt-1.5 text-sm text-red-600">{error}</p>}
            {helperText && !error && <p className="mt-1.5 text-sm text-slate-500">{helperText}</p>}
        </div>
    );
};

export default Input;
