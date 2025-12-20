import React from 'react';
import { Loader2 } from 'lucide-react';

const Button = ({
    children,
    variant = 'primary', // primary, secondary, ghost, destruction
    size = 'md', // sm, md, lg
    className = '',
    isLoading = false,
    disabled = false,
    icon: Icon,
    ...props
}) => {
    const baseStyles = "inline-flex items-center justify-center font-semibold rounded-lg transition-all duration-200 focus:outline-none focus:ring-2 focus:ring-offset-1 disabled:opacity-50 disabled:cursor-not-allowed";

    const variants = {
        primary: "bg-primary-600 text-white shadow-sm hover:bg-primary-700 focus:ring-primary-500 border border-transparent",
        secondary: "bg-white text-slate-700 border border-slate-300 shadow-sm hover:bg-slate-50 focus:ring-slate-300",
        ghost: "bg-transparent text-slate-600 hover:bg-slate-50 hover:text-slate-900 focus:ring-slate-200",
        destructive: "bg-red-600 text-white shadow-sm hover:bg-red-700 focus:ring-red-500 border border-transparent",
    };

    const sizes = {
        sm: "px-3 py-2 text-sm",
        md: "px-4 py-2.5 text-sm",
        lg: "px-5 py-3 text-base",
    };

    return (
        <button
            className={`${baseStyles} ${variants[variant]} ${sizes[size]} ${className}`}
            disabled={disabled || isLoading}
            {...props}
        >
            {isLoading && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
            {!isLoading && Icon && <Icon className="mr-2 h-4 w-4" />}
            {children}
        </button>
    );
};

export default Button;
