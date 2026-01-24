import React from 'react';

interface CardProps {
    children: React.ReactNode;
    className?: string;
    title?: string;
}

export const Card: React.FC<CardProps> = ({ children, className = '', title }) => {
    return (
        <div className={`bg-white border-2 border-black rounded-lg p-6 shadow-lg ${className}`}>
            {title && <h3 className="text-xl font-bold mb-4 border-b-2 border-black pb-2">{title}</h3>}
            {children}
        </div>
    );
};
