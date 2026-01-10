import React, { useRef, useMemo, Suspense, useState, useEffect } from 'react';
import { motion, useScroll, useTransform, useSpring } from 'framer-motion';
import { Canvas, useFrame } from '@react-three/fiber';
import { OrbitControls, Float, Sphere, MeshDistortMaterial, Torus, Text } from '@react-three/drei';
import Navbar from '../components/Navbar';
import useCms from '../hooks/useCms';
import { 
    CheckCircle, 
    BarChart3, 
    Package, 
    Users, 
    TrendingUp, 
    Smartphone,
    Shield,
    Zap,
    Globe,
    CreditCard,
    Receipt,
    Calculator,
    Database,
    Cloud,
    Settings,
    Award,
    Clock,
    Target,
    Rocket,
    ArrowRight,
    Cpu,
    Server,
    Wind
} from 'lucide-react';
import * as THREE from 'three';

// #region 3D Components

const Particles = ({ count = 100, mouseX, mouseY, scrollYProgress }) => {
    const particles = useMemo(() => {
        const temp = [];
        for (let i = 0; i < count; i++) {
            const size = Math.random() * 1.5 + 0.5;
            const x = (Math.random() - 0.5) * 2;
            const y = (Math.random() - 0.5) * 2;
            const speed = Math.random() * 0.2 + 0.1;
            temp.push({ size, x, y, speed });
        }
        return temp;
    }, [count]);

    return (
        <div className="fixed inset-0 z-0 pointer-events-none">
            {particles.map((p, i) => (
                <motion.div
                    key={i}
                    className="absolute rounded-full bg-white/10"
                    style={{
                        width: p.size,
                        height: p.size,
                        x: useTransform(mouseX, [-1, 1], [p.x * 50 - 25, p.x * -50 + 25]),
                        y: useTransform(mouseY, [-1, 1], [p.y * 50 - 25, p.y * -50 + 25]),
                        left: `${50 + p.x * 50}%`,
                        top: `${50 + p.y * 50}%`,
                        scale: useTransform(scrollYProgress, [0, 1], [1, 3 - p.speed * 5]),
                        opacity: useTransform(scrollYProgress, [0, 1], [1, 0])
                    }}
                />
            ))}
        </div>
    );
};

const FeatureSphere = ({ position, color, feature, index, onHover, onPointerOut }) => {
    const meshRef = useRef();
    
    return (
        <Float speed={1.5} rotationIntensity={0.5} floatIntensity={0.5}>
            <Sphere 
                ref={meshRef} 
                position={position} 
                args={[0.8, 32, 32]}
                onPointerOver={(e) => (e.stopPropagation(), onHover(index))}
                onPointerOut={onPointerOut}
            >
                <MeshDistortMaterial
                    color={color}
                    attach="material"
                    distort={0.3}
                    speed={2}
                    roughness={0.2}
                    metalness={0.8}
                />
            </Sphere>
        </Float>
    );
};

const TorusConnection = ({ start, end }) => {
    const ref = useRef();

    const startVec = new THREE.Vector3(...start);
    const endVec = new THREE.Vector3(...end);
    const distance = startVec.distanceTo(endVec);
    const midPoint = new THREE.Vector3().addVectors(startVec, endVec).multiplyScalar(0.5);

    useFrame(() => {
        if (ref.current) {
            ref.current.position.copy(midPoint);
            ref.current.lookAt(endVec);
        }
    });

    return (
        <Torus ref={ref} args={[distance / 2, 0.02, 8, 50]}>
            <meshStandardMaterial color="#888" emissive="#333" roughness={0.5} />
        </Torus>
    );
};

const FeatureShowcase3D = () => {
    const [hovered, setHovered] = useState(null);
    const [infoVisible, setInfoVisible] = useState(false);

    useEffect(() => {
        let timeout;
        if (hovered !== null) {
            timeout = setTimeout(() => setInfoVisible(true), 500);
        } else {
            setInfoVisible(false);
        }
        return () => clearTimeout(timeout);
    }, [hovered]);

    const features = [
        { name: 'POS', color: '#3b82f6', position: [-3, 0, 0] },
        { name: 'Inventory', color: '#10b981', position: [0, 2, 0] },
        { name: 'Reports', color: '#f59e0b', position: [3, 0, 0] },
        { name: 'Analytics', color: '#ef4444', position: [0, -2, 0] },
        { name: 'Cloud', color: '#8b5cf6', position: [-2, 1, 2] },
        { name: 'Mobile', color: '#06b6d4', position: [2, -1, 2] }
    ];

    return (
        <div className="relative w-full h-full">
            <Canvas camera={{ position: [0, 0, 10], fov: 75 }}>
                <ambientLight intensity={0.6} />
                <directionalLight position={[10, 10, 5]} intensity={1.2} />
                <pointLight position={[-10, -10, -10]} color="#3b82f6" intensity={0.8} />
                
                {features.map((feature, index) => (
                    <FeatureSphere
                        key={index}
                        position={feature.position}
                        color={feature.color}
                        feature={feature.name}
                        index={index}
                        onHover={setHovered}
                        onPointerOut={() => setHovered(null)}
                    />
                ))}

                {/* Torus connections */}
                <TorusConnection start={features[0].position} end={features[1].position} />
                <TorusConnection start={features[1].position} end={features[2].position} />
                <TorusConnection start={features[2].position} end={features[3].position} />
                <TorusConnection start={features[3].position} end={features[0].position} />
                <TorusConnection start={features[4].position} end={features[0].position} />
                <TorusConnection start={features[5].position} end={features[2].position} />
                
                <OrbitControls
                    enablePan={false}
                    enableZoom={false}
                    maxPolarAngle={Math.PI / 2}
                    minPolarAngle={Math.PI / 2}
                    autoRotate
                    autoRotateSpeed={0.5}
                />
            </Canvas>
            <motion.div 
                className="absolute top-4 left-4 bg-black/30 backdrop-blur-sm p-4 rounded-lg border border-white/10 text-white text-sm"
                initial={{ opacity: 0, x: -20 }}
                animate={{ opacity: infoVisible ? 1 : 0, x: infoVisible ? 0 : -20 }}
                transition={{ duration: 0.3 }}
            >
                {hovered !== null ? `Fitur: ${features[hovered].name}` : 'Arahkan ke node untuk info'}
            </motion.div>
            <div className="absolute bottom-4 right-4 text-xs text-slate-400 flex items-center gap-2">
                {features.map((f, i) => (
                    <div key={i} className="flex items-center gap-1">
                        <div className="w-2 h-2 rounded-full" style={{ backgroundColor: f.color }}></div>
                        <span>{f.name}</span>
                    </div>
                ))}
            </div>
        </div>
    );
};

const BusinessImpact3D = () => {
    const items = [
        { text: "Efisiensi +30%", position: [-3, 0, 0], color: "#22c55e" },
        { text: "Profit +15%", position: [3, 0, 0], color: "#3b82f6" },
        { text: "Kepuasan Pelanggan +25%", position: [0, 3, 0], color: "#f97316" },
    ];

    return (
        <Canvas camera={{ position: [0, 0, 8], fov: 50 }}>
            <ambientLight intensity={0.7} />
            <directionalLight intensity={1} position={[5, 5, 5]} />
            <Suspense fallback={null}>
                {items.map((item, i) => (
                    <Float key={i} speed={1.5} rotationIntensity={0.2} floatIntensity={0.8}>
                        <Torus position={item.position} args={[1, 0.1, 16, 100]}>
                            <meshStandardMaterial color={item.color} roughness={0.1} metalness={0.9} />
                        </Torus>
                        <Text
                            position={[item.position[0], item.position[1], item.position[2] + 1.2]}
                            color="white"
                            fontSize={0.4}
                            maxWidth={2}
                            lineHeight={1}
                            letterSpacing={0.02}
                            textAlign="center"
                            anchorX="center"
                            anchorY="middle"
                        >
                            {item.text}
                        </Text>
                    </Float>
                ))}
            </Suspense>
            <OrbitControls enableZoom={false} autoRotate autoRotateSpeed={0.4} />
        </Canvas>
    );
};

// #endregion

// #region UI Components

const FeatureCard = ({ icon: Icon, title, description, benefits, color, delay = 0 }) => {
    const cardRef = useRef();
    const [isHovered, setIsHovered] = useState(false);
    
    return (
        <motion.div
            ref={cardRef}
            initial={{ opacity: 0, y: 50 }}
            whileInView={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6, delay }}
            whileHover={{ 
                scale: 1.05,
                rotateY: 5,
                transition: { duration: 0.3 }
            }}
            viewport={{ once: true }}
            className="group relative bg-gradient-to-br from-slate-800/50 to-slate-900/50 backdrop-blur-sm border border-white/10 rounded-3xl p-8 hover:border-white/20 transition-all duration-500 cursor-pointer"
            style={{
                transformStyle: 'preserve-3d',
                perspective: '1000px'
            }}
            onHoverStart={() => setIsHovered(true)}
            onHoverEnd={() => setIsHovered(false)}
        >
            <motion.div
                className="absolute inset-0 bg-gradient-to-br from-blue-500/10 to-purple-500/10 rounded-3xl opacity-0 group-hover:opacity-100 transition-opacity duration-300"
                style={{ transform: 'translateZ(20px)' }}
            />
            
            <motion.div
                className="absolute inset-0 rounded-3xl"
                animate={{
                    boxShadow: isHovered 
                        ? `0 0 30px ${color.split(' ')[0].replace('from-','rgba(').replace('-500',',0.3)').replace('blue','59, 130, 246').replace('green','16, 185, 129').replace('amber','245, 158, 11').replace('purple','139, 92, 246').replace('indigo','99, 102, 241').replace('teal','20, 184, 166')}, 0 0 60px ${color.split(' ')[1].replace('to-','rgba(').replace('-600',',0.2)').replace('blue','96, 165, 250').replace('green','5, 150, 105').replace('amber','217, 119, 6').replace('purple','124, 58, 237').replace('indigo','88, 81, 216').replace('teal','13, 148, 136')}`
                        : '0 0 0px rgba(0,0,0,0)'
                }}
                transition={{ duration: 0.3 }}
            />
            
            <div className="relative z-10">
                <motion.div 
                    className={`w-16 h-16 rounded-2xl bg-gradient-to-br ${color} flex items-center justify-center mb-6 shadow-lg group-hover:shadow-xl transition-all duration-300`}
                    style={{ transform: 'translateZ(40px)' }}
                    whileHover={{ rotate: 360, scale: 1.1 }}
                    transition={{ duration: 0.5 }}
                >
                    <Icon size={28} className="text-white" />
                </motion.div>
                
                <motion.h3 
                    className="text-2xl font-bold text-white mb-4 group-hover:text-blue-300 transition-colors duration-300"
                    style={{ transform: 'translateZ(30px)' }}
                >
                    {title}
                </motion.h3>
                
                <p className="text-slate-300 leading-relaxed mb-6 group-hover:text-slate-200 transition-colors duration-300">
                    {description}
                </p>
                
                <div className="space-y-3">
                    {benefits.map((benefit, index) => (
                        <motion.div
                            key={index}
                            initial={{ opacity: 0, x: -20 }}
                            whileInView={{ opacity: 1, x: 0 }}
                            transition={{ duration: 0.3, delay: delay + 0.2 + index * 0.1 }}
                            whileHover={{ x: 5, scale: 1.02 }}
                            className="flex items-center gap-3 group/benefit"
                        >
                            <motion.div 
                                className="w-2 h-2 rounded-full bg-gradient-to-r from-indigo-400 to-purple-400 group-hover/benefit:scale-125 transition-transform duration-300"
                            />
                            <span className="text-slate-400 text-sm group-hover/benefit:text-slate-200 transition-colors duration-300">
                                {benefit}
                            </span>
                        </motion.div>
                    ))}
                </div>
                
                <motion.div
                    className="absolute bottom-6 right-6 opacity-0 group-hover:opacity-100 transition-opacity duration-300"
                    style={{ transform: 'translateZ(50px)' }}
                >
                    <ArrowRight size={20} className="text-blue-400" />
                </motion.div>
            </div>
        </motion.div>
    );
};

const StatCard = ({ value, label, icon: Icon, color, delay = 0 }) => (
    <motion.div
        initial={{ opacity: 0, scale: 0.8 }}
        whileInView={{ opacity: 1, scale: 1 }}
        transition={{ duration: 0.6, delay }}
        viewport={{ once: true }}
        className="bg-gradient-to-br from-slate-800/30 to-slate-900/30 backdrop-blur-sm border border-white/10 rounded-2xl p-6 text-center hover:border-white/20 transition-all duration-300"
    >
        <div className={`w-12 h-12 rounded-xl bg-gradient-to-br ${color} flex items-center justify-center mx-auto mb-4`}>
            <Icon size={24} className="text-white" />
        </div>
        <div className="text-3xl font-bold text-white mb-2">{value}</div>
        <div className="text-slate-400 text-sm">{label}</div>
    </motion.div>
);

const TechnologyStack = () => {
    const techs = [
        { name: "React", icon: Wind, description: "Frontend library" },
        { name: "Node.js", icon: Cpu, description: "Backend runtime" },
        { name: "MongoDB", icon: Database, description: "NoSQL Database" },
        { name: "Socket.IO", icon: Zap, description: "Real-time engine" },
        { name: "Three.js", icon: Globe, description: "3D Graphics" },
        { name: "Cloudflare", icon: Server, description: "CDN & Security" },
    ];

    return (
        <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-8">
            {techs.map((tech, i) => (
                <motion.div
                    key={tech.name}
                    initial={{ opacity: 0, y: 20 }}
                    whileInView={{ opacity: 1, y: 0 }}
                    transition={{ duration: 0.5, delay: i * 0.1 }}
                    viewport={{ once: true }}
                    className="flex flex-col items-center text-center p-4 rounded-xl bg-white/5 hover:bg-white/10 transition-colors"
                >
                    <tech.icon size={32} className="mb-3 text-blue-400" />
                    <h4 className="font-bold text-white">{tech.name}</h4>
                    <p className="text-xs text-slate-400">{tech.description}</p>
                </motion.div>
            ))}
        </div>
    );
};

// #endregion

const Features = () => {
    const containerRef = useRef();
    const { scrollYProgress } = useScroll({
        target: containerRef,
        offset: ["start start", "end end"]
    });

    const [mousePosition, setMousePosition] = useState({ x: 0, y: 0 });
    
    useEffect(() => {
        const handleMouseMove = (e) => {
            setMousePosition({
                x: (e.clientX / window.innerWidth - 0.5) * 2,
                y: (e.clientY / window.innerHeight - 0.5) * 2
            });
        };
        window.addEventListener('mousemove', handleMouseMove);
        return () => window.removeEventListener('mousemove', handleMouseMove);
    }, []);

    const smoothMouse = {
        x: useSpring(useTransform(useSpring(mousePosition.x), v => v * 20), { stiffness: 400, damping: 30 }),
        y: useSpring(useTransform(useSpring(mousePosition.y), v => v * 20), { stiffness: 400, damping: 30 })
    };

    const heroOpacity = useTransform(scrollYProgress, [0, 0.15], [1, 0]);
    const heroScale = useTransform(scrollYProgress, [0, 0.15], [1, 0.8]);

    const features = [
        {
            icon: Calculator,
            title: "Point of Sale (POS) Cerdas",
            description: "Sistem kasir modern dengan antarmuka intuitif dan pemrosesan transaksi super cepat. Mendukung berbagai metode pembayaran dan integrasi perangkat keras.",
            benefits: [
                "Proses transaksi dalam hitungan detik",
                "Mendukung cash, card, dan digital payment",
                "Antarmuka responsif untuk tablet dan mobile",
                "Offline mode saat internet terputus",
                "Custom receipt dan tax calculation"
            ],
            color: "from-blue-500 to-blue-600"
        },
        {
            icon: Package,
            title: "Manajemen Inventory Real-time",
            description: "Pantau stok barang secara otomatis dengan sistem tracking canggih. Dapatkan notifikasi low stock dan analisis penjualan produk.",
            benefits: [
                "Update stok otomatis setiap transaksi",
                "Notifikasi stok menipis via WhatsApp",
                "Analisis produk terlaris dan slow moving",
                "Multi-location inventory tracking",
                "Purchase order otomatis ke supplier"
            ],
            color: "from-green-500 to-green-600"
        },
        {
            icon: BarChart3,
            title: "Analytics & Business Intelligence",
            description: "Dapatkan insight mendalam tentang performa bisnis Anda dengan dashboard analitik real-time dan laporan keuangan komprehensif.",
            benefits: [
                "Dashboard real-time 24/7",
                "Laporan profit & loss otomatis",
                "Analisis tren penjualan harian/mingguan/bulanan",
                "Customer behavior analytics",
                "Export laporan ke Excel/PDF"
            ],
            color: "from-amber-500 to-amber-600"
        },
        {
            icon: Users,
            title: "Customer Relationship Management",
            description: "Bangun hubungan lebih baik dengan pelanggan melalui sistem CRM terintegrasi. Tracking purchase history dan loyalty program.",
            benefits: [
                "Database customer otomatis",
                "Purchase history dan preference tracking",
                "Loyalty point dan reward system",
                "SMS/WhatsApp marketing integration",
                "Customer segmentation untuk promo target"
            ],
            color: "from-purple-500 to-purple-600"
        },
        {
            icon: CreditCard,
            title: "Multi-Payment Gateway",
            description: "Terima berbagai jenis pembayaran dari cash hingga digital wallet. Integrasi dengan payment gateway terpercaya di Indonesia.",
            benefits: [
                "Integrasi QRIS otomatis",
                "Kartu debit/kredit dengan EDC",
                "Digital wallet: GoPay, OVO, ShopeePay",
                "Split payment untuk group order",
                "Refund dan partial payment support"
            ],
            color: "from-indigo-500 to-indigo-600"
        },
        {
            icon: Receipt,
            title: "E-Receipt & Invoice Management",
            description: "Sistem digital receipt yang ramah lingkungan dan mudah ditracking. Kirim invoice otomatis via email atau WhatsApp.",
            benefits: [
                "Digital receipt via QR code",
                "Email/WhatsApp invoice otomatis",
                "Custom template untuk branding",
                "Tax calculation dan PPN support",
                "Archive system untuk audit trail"
            ],
            color: "from-teal-500 to-teal-600"
        },
        {
            icon: Database,
            title: "Cloud Backup & Sync",
            description: "Data Anda aman di cloud dengan sistem backup otomatis. Akses data dari mana saja dengan keamanan tingkat tinggi.",
            benefits: [
                "Auto backup setiap jam",
                "256-bit encryption security",
                "Multi-device synchronization",
                "Offline mode dengan sync otomatis",
                "Data recovery dan restore point"
            ],
            color: "from-cyan-500 to-cyan-600"
        },
        {
            icon: Settings,
            title: "Multi-User Access Control",
            description: "Kelola tim Anda dengan sistem role-based access control. Berikan hak akses sesuai dengan job description masing-masing.",
            benefits: [
                "Role-based permission system",
                "Owner, Manager, Cashier, dan Staff level",
                "Activity log untuk setiap user",
                "Shift management untuk kasir",
                "Remote monitoring dan control"
            ],
            color: "from-orange-500 to-orange-600"
        },
        {
            icon: Target,
            title: "Flash Sales & Promo Engine",
            description: "Buat campaign marketing yang menarik dengan promo engine canggih. Atur diskon, bundle deal, dan loyalty program dengan mudah.",
            benefits: [
                "Flash sales dengan countdown timer",
                "Bundle deals dan package offers",
                "Member discount otomatis",
                "Happy hour pricing",
                "Voucher dan coupon management"
            ],
            color: "from-red-500 to-red-600"
        }
    ];

    const stats = [
        { value: "50+", label: "Fitur Premium", icon: Award, color: "from-yellow-500 to-orange-500" },
        { value: "10K+", label: "Merchant Aktif", icon: TrendingUp, color: "from-green-500 to-emerald-500" },
        { value: "99.9%", label: "Uptime Server", icon: Shield, color: "from-blue-500 to-cyan-500" },
        { value: "24/7", label: "Support Team", icon: Clock, color: "from-purple-500 to-pink-500" }
    ];

    return (
        <div ref={containerRef} className="min-h-screen bg-gradient-to-b from-[#0a0b0f] via-[#0b1020] to-[#0a0b0f] font-sans text-slate-200 overflow-x-hidden">
            <Navbar />
            <Particles mouseX={smoothMouse.x} mouseY={smoothMouse.y} scrollYProgress={scrollYProgress} />
            
            <motion.section 
                style={{ opacity: heroOpacity, scale: heroScale }}
                className="h-screen flex items-center justify-center flex-col text-center sticky top-0"
            >
                <motion.h1 
                    style={{ x: smoothMouse.x, y: smoothMouse.y }}
                    className="text-5xl md:text-7xl font-bold text-white mb-6 bg-gradient-to-r from-blue-400 via-purple-400 to-pink-400 bg-clip-text text-transparent"
                >
                    Fitur-Fitur Unggulan
                </motion.h1>
                <motion.p 
                    style={{ x: smoothMouse.x, y: smoothMouse.y }}
                    className="text-xl md:text-2xl text-slate-300 max-w-3xl mx-auto leading-relaxed"
                >
                    Solusi lengkap untuk transformasi digital bisnis Anda. 
                    <span className="text-blue-400 font-semibold"> RanaPOS</span> menghadirkan teknologi canggih 
                    dengan antarmuka modern untuk kemudahan operasional.
                </motion.p>
                <motion.div
                    initial={{ opacity: 0, y: 30 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ duration: 0.8, delay: 0.4 }}
                    className="mt-12"
                >
                    <div className="inline-flex items-center gap-4 px-6 py-3 bg-white/10 backdrop-blur-sm border border-white/20 rounded-full">
                        <div className="w-3 h-3 bg-green-400 rounded-full animate-pulse"></div>
                        <span>Lebih dari 10.000 merchant telah mempercayai kami</span>
                    </div>
                </motion.div>
            </motion.section>
            
            <div className="relative z-10">
                <section className="py-24 px-4 md:px-8">
                    <div className="max-w-6xl mx-auto">
                        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-8">
                            {stats.map((stat, index) => (
                                <StatCard key={index} {...stat} delay={index * 0.1} />
                            ))}
                        </div>
                    </div>
                </section>

                <section className="py-24 px-4 md:px-8 bg-black/20">
                    <div className="max-w-6xl mx-auto">
                        <div className="text-center mb-16">
                            <h2 className="text-4xl md:text-5xl font-bold text-white mb-4">Semua yang Anda Butuhkan</h2>
                            <p className="text-lg text-slate-400 max-w-2xl mx-auto">Dari kasir hingga laporan keuangan, kami menyediakan alat yang tepat untuk setiap aspek bisnis Anda.</p>
                        </div>
                        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
                            {features.map((feature, index) => (
                                <FeatureCard key={index} {...feature} delay={index * 0.1} />
                            ))}
                        </div>
                    </div>
                </section>

                <section className="py-24 px-4 md:px-8">
                    <div className="max-w-6xl mx-auto">
                        <div className="text-center mb-16">
                            <h2 className="text-4xl md:text-5xl font-bold text-white mb-4">Visualisasi Ekosistem Fitur</h2>
                            <p className="text-lg text-slate-400 max-w-3xl mx-auto">Lihat bagaimana setiap fitur terhubung dan saling mendukung untuk menciptakan ekosistem bisnis yang kuat dan terintegrasi.</p>
                        </div>
                        <div className="h-[500px] w-full rounded-2xl border border-white/10 bg-gradient-to-b from-slate-900 to-black/50 p-4">
                            <FeatureShowcase3D />
                        </div>
                    </div>
                </section>

                <section className="py-24 px-4 md:px-8 bg-black/20">
                    <div className="max-w-6xl mx-auto">
                        <div className="text-center mb-16">
                            <h2 className="text-4xl md:text-5xl font-bold text-white mb-4">Dampak Nyata bagi Bisnis Anda</h2>
                            <p className="text-lg text-slate-400 max-w-2xl mx-auto">RanaPOS bukan hanya software, tapi partner pertumbuhan yang memberikan hasil terukur.</p>
                        </div>
                        <div className="h-[400px] w-full">
                            <BusinessImpact3D />
                        </div>
                    </div>
                </section>

                <section className="py-24 px-4 md:px-8">
                    <div className="max-w-6xl mx-auto">
                        <div className="text-center mb-16">
                            <motion.h2 
                                initial={{ opacity: 0, y: 20 }}
                                whileInView={{ opacity: 1, y: 0 }}
                                transition={{ duration: 0.5 }}
                                viewport={{ once: true }}
                                className="text-4xl md:text-5xl font-bold text-white mb-4"
                            >
                                Dibangun dengan Teknologi Terdepan
                            </motion.h2>
                            <p className="text-lg text-slate-400 max-w-2xl mx-auto">Kami menggunakan tumpukan teknologi modern untuk memastikan performa, keamanan, dan skalabilitas terbaik.</p>
                        </div>
                        <TechnologyStack />
                    </div>
                </section>
            </div>
        </div>
    );
};

export default Features;
