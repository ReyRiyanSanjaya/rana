import React, { useRef } from 'react';
import { useFrame } from '@react-three/fiber';
import { Float, Sphere, Torus, Octahedron } from '@react-three/drei';

function MovingShape({ position, rotation, color, geometry: Geometry, scale = 1, speed = 1 }) {
    const meshRef = useRef();

    useFrame((state) => {
        const t = state.clock.getElapsedTime();
        meshRef.current.rotation.x = Math.sin(t * 0.2 * speed) * 0.5;
        meshRef.current.rotation.y = Math.cos(t * 0.3 * speed) * 0.5;
    });

    return (
        <Float speed={2 * speed} rotationIntensity={1} floatIntensity={1}>
            <Geometry ref={meshRef} position={position} rotation={rotation} scale={scale}>
                <meshStandardMaterial
                    color={color}
                    roughness={0.1}
                    metalness={0.8}
                    emissive={color}
                    emissiveIntensity={0.2}
                />
            </Geometry>
        </Float>
    );
}

export default function Experience() {
    return (
        <>
            <ambientLight intensity={0.5} />
            <directionalLight position={[10, 10, 5]} intensity={1.5} color="#ffffff" />
            <pointLight position={[-10, -10, -10]} intensity={1} color="#BF092F" />

            {/* Hero Shapes */}
            <MovingShape
                geometry={Torus}
                position={[2, 0, 0]}
                rotation={[Math.PI / 4, 0, 0]}
                scale={1.5}
                color="#E11D48" // Rose 600
                speed={1}
            />
            <MovingShape
                geometry={Sphere}
                position={[-2, 1, -2]}
                scale={1}
                color="#FECDD3" // Rose 200
                speed={0.8}
            />
            <MovingShape
                geometry={Octahedron}
                position={[3, -2, -1]}
                scale={1.2}
                color="#9F1239" // Rose 800
                speed={1.2}
            />

            {/* Background Elements */}
            <MovingShape
                geometry={Sphere}
                position={[-5, 4, -8]}
                scale={0.5}
                color="#FFE4E6" // Rose 100
                speed={0.5}
            />
            <MovingShape
                geometry={Torus}
                position={[6, -4, -6]}
                scale={0.8}
                color="#FDA4AF" // Rose 300
                speed={0.7}
            />
        </>
    );
}
