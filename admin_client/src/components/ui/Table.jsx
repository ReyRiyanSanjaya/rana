import React from 'react';

const Table = ({ children, className = '' }) => (
    <div className={`overflow-x-auto ${className}`}>
        <table className="min-w-full divide-y divide-slate-200">
            {children}
        </table>
    </div>
);

const Thead = ({ children }) => (
    <thead className="bg-slate-50">
        {children}
    </thead>
);

const Tbody = ({ children }) => (
    <tbody className="bg-white divide-y divide-slate-200">
        {children}
    </tbody>
);

const Th = ({ children, className = '', ...props }) => (
    <th
        className={`px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider ${className}`}
        {...props}
    >
        {children}
    </th>
);

const Td = ({ children, className = '', ...props }) => (
    <td
        className={`px-6 py-4 whitespace-nowrap text-sm text-slate-500 ${className}`}
        {...props}
    >
        {children}
    </td>
);

const Tr = ({ children, className = '', ...props }) => (
    <tr
        className={`hover:bg-slate-50 transition-colors ${className}`}
        {...props}
    >
        {children}
    </tr>
);

export { Table, Thead, Tbody, Th, Td, Tr };
