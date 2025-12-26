import { useState, useEffect } from 'react';
import api from '../services/api';

const useCms = () => {
    const [cmsContent, setCmsContent] = useState({
        // Defaults
        CMS_HERO_TITLE: 'Elevate Your Business Beyond Limits',
        CMS_HERO_SUBTITLE: 'Experience the perfect fusion of aesthetic design and powerful technology.',
        CMS_ABOUT_US: '<p>Rana is a leading POS platform...</p>',
        CMS_CONTACT_EMAIL: 'support@rana.com',
        CMS_CONTACT_PHONE: '+62 812 3456 7890',
        CMS_CORE_VALUES: [],
        CMS_FEATURES_LIST: []
    });
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        const fetchCms = async () => {
            try {
                const res = await api.get('/system/cms-content');
                const data = res.data.data;
                const parsed = { ...data };

                // Parse JSON fields
                if (parsed.CMS_CORE_VALUES && typeof parsed.CMS_CORE_VALUES === 'string') {
                    try { parsed.CMS_CORE_VALUES = JSON.parse(parsed.CMS_CORE_VALUES); } catch (e) { }
                }
                if (parsed.CMS_FEATURES_LIST && typeof parsed.CMS_FEATURES_LIST === 'string') {
                    try { parsed.CMS_FEATURES_LIST = JSON.parse(parsed.CMS_FEATURES_LIST); } catch (e) { }
                }

                setCmsContent(prev => ({ ...prev, ...parsed }));
            } catch (error) {
                console.error("Failed to load CMS content", error);
            } finally {
                setLoading(false);
            }
        };

        fetchCms();
    }, []);

    return { cmsContent, loading };
};

export default useCms;
