import React, { useState, useEffect } from 'react';
import ReactQuill from 'react-quill-new';
import 'react-quill-new/dist/quill.snow.css';
import {
  FiEdit2,
  FiTrash2,
  FiPlus,
  FiSave,
  FiX,
  FiImage,
  FiEye,
  FiMonitor,
  FiTablet,
  FiSmartphone,
  FiArrowLeft,
  FiCheck,
  FiClock,
  FiType,
  FiSearch,
  FiLayout
} from 'react-icons/fi';
import Swal from 'sweetalert2';
import api from '../api';
import AdminLayout from '../components/AdminLayout';

// --- Components ---

const BlogPreviewModal = ({ isOpen, onClose, data }) => {
  const [viewMode, setViewMode] = useState('desktop'); // desktop, tablet, mobile

  if (!isOpen) return null;

  const getContainerWidth = () => {
    switch (viewMode) {
      case 'mobile': return 'max-w-[375px]';
      case 'tablet': return 'max-w-[768px]';
      default: return 'max-w-5xl';
    }
  };

  const wordCount = (data.content || '').replace(/<[^>]*>/g, '').split(/\s+/).filter(w => w.length > 0).length || 0;
  const readTime = Math.ceil(wordCount / 200);

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/90 backdrop-blur-md p-4 animate-in fade-in duration-200">
      <div className="bg-slate-900 w-full h-full max-h-[95vh] rounded-2xl flex flex-col overflow-hidden shadow-2xl border border-slate-700">
        {/* Preview Header */}
        <div className="flex items-center justify-between px-6 py-4 bg-slate-800 border-b border-slate-700 shrink-0">
          <div className="flex items-center gap-6">
            <h3 className="text-white font-semibold flex items-center gap-2 text-lg">
              <span className="p-1.5 bg-blue-500/10 text-blue-400 rounded-lg"><FiEye size={20} /></span>
              Device Preview
            </h3>
            <div className="h-6 w-px bg-slate-700"></div>
            <div className="flex bg-slate-900/50 p-1 rounded-lg border border-slate-700/50">
              <button
                onClick={() => setViewMode('desktop')}
                className={`flex items-center gap-2 px-3 py-1.5 rounded-md transition-all text-sm font-medium ${viewMode === 'desktop' ? 'bg-blue-600 text-white shadow-lg' : 'text-slate-400 hover:text-white hover:bg-slate-800'}`}
              >
                <FiMonitor size={16} /> Desktop
              </button>
              <button
                onClick={() => setViewMode('tablet')}
                className={`flex items-center gap-2 px-3 py-1.5 rounded-md transition-all text-sm font-medium ${viewMode === 'tablet' ? 'bg-blue-600 text-white shadow-lg' : 'text-slate-400 hover:text-white hover:bg-slate-800'}`}
              >
                <FiTablet size={16} /> Tablet
              </button>
              <button
                onClick={() => setViewMode('mobile')}
                className={`flex items-center gap-2 px-3 py-1.5 rounded-md transition-all text-sm font-medium ${viewMode === 'mobile' ? 'bg-blue-600 text-white shadow-lg' : 'text-slate-400 hover:text-white hover:bg-slate-800'}`}
              >
                <FiSmartphone size={16} /> Mobile
              </button>
            </div>
          </div>
          <button
            onClick={onClose}
            className="p-2 hover:bg-red-500/10 hover:text-red-400 rounded-full text-slate-400 transition-all"
          >
            <FiX size={24} />
          </button>
        </div>

        {/* Preview Content Area */}
        <div className="flex-1 overflow-y-auto bg-slate-950/50 p-8 flex justify-center relative">
          <div className="absolute inset-0 bg-[radial-gradient(ellipse_at_center,_var(--tw-gradient-stops))] from-blue-900/20 via-slate-950 to-slate-950 pointer-events-none"></div>
          
          <div className={`relative z-10 w-full transition-all duration-500 ease-out ${getContainerWidth()} bg-white min-h-full shadow-2xl overflow-hidden flex flex-col ${viewMode === 'mobile' ? 'rounded-[2.5rem] border-[8px] border-slate-800' : 'rounded-xl'}`}>
            
            {/* Mock Browser/App Bar */}
            <div className={`bg-white/90 backdrop-blur-sm border-b border-slate-100 sticky top-0 z-20 ${viewMode === 'mobile' ? 'pt-6 px-4 pb-2' : 'px-4 py-3'}`}>
              {viewMode === 'mobile' ? (
                <div className="flex justify-between items-center">
                   <div className="text-xs font-semibold text-slate-900">9:41</div>
                   <div className="flex gap-1.5">
                     <div className="w-4 h-4 rounded-full border border-slate-300"></div>
                     <div className="w-4 h-4 rounded-full border border-slate-300"></div>
                   </div>
                </div>
              ) : (
                <div className="flex items-center gap-3">
                  <div className="flex gap-1.5">
                    <div className="w-3 h-3 rounded-full bg-red-400/80"></div>
                    <div className="w-3 h-3 rounded-full bg-yellow-400/80"></div>
                    <div className="w-3 h-3 rounded-full bg-green-400/80"></div>
                  </div>
                  <div className="flex-1 mx-4 bg-slate-100 rounded-md h-7 text-xs flex items-center px-3 text-slate-400 font-mono">
                    https://mysite.com/blog/{data.slug || 'untitled-post'}
                  </div>
                </div>
              )}
            </div>

            {/* Actual Content */}
            <div className="flex-1 bg-white">
              {data.image && (
                <div className="relative w-full aspect-video group overflow-hidden">
                  <img src={data.image} alt={data.title} className="w-full h-full object-cover transition-transform duration-700 group-hover:scale-105" />
                  <div className="absolute inset-0 bg-gradient-to-t from-black/60 to-transparent opacity-60"></div>
                  <div className="absolute bottom-0 left-0 p-6 md:p-8 text-white">
                     <div className="flex flex-wrap gap-2 mb-3">
                      {data.tags && data.tags.split(',').map((tag, i) => (
                        <span key={i} className="px-2.5 py-0.5 bg-white/20 backdrop-blur-md border border-white/30 rounded-full text-xs font-medium uppercase tracking-wider">
                          {tag.trim()}
                        </span>
                      ))}
                    </div>
                  </div>
                </div>
              )}

              <div className="p-6 md:p-10 lg:p-12 max-w-4xl mx-auto">
                {!data.image && (
                   <div className="flex flex-wrap gap-2 mb-6">
                    {data.tags && data.tags.split(',').map((tag, i) => (
                      <span key={i} className="px-3 py-1 bg-blue-50 text-blue-600 rounded-full text-xs font-bold uppercase tracking-wider">
                        {tag.trim()}
                      </span>
                    ))}
                  </div>
                )}
                
                <h1 className="text-3xl md:text-5xl font-black text-slate-900 mb-6 leading-tight tracking-tight">
                  {data.title || 'Untitled Post'}
                </h1>

                <div className="flex items-center gap-4 text-sm text-slate-500 mb-10 pb-8 border-b border-slate-100 font-medium">
                  <div className="flex items-center gap-2">
                    <div className="w-8 h-8 rounded-full bg-blue-100 flex items-center justify-center text-blue-600 font-bold">A</div>
                    <span>Admin</span>
                  </div>
                  <span>•</span>
                  <span>{new Date().toLocaleDateString('en-US', { month: 'long', day: 'numeric', year: 'numeric' })}</span>
                  <span>•</span>
                  <span className="flex items-center gap-1"><FiClock size={14}/> {readTime} min read</span>
                </div>

                <div 
                  className="prose prose-lg prose-slate max-w-none 
                    prose-headings:font-bold prose-headings:tracking-tight prose-headings:text-slate-900
                    prose-p:text-slate-600 prose-p:leading-relaxed
                    prose-a:text-blue-600 prose-a:no-underline hover:prose-a:underline
                    prose-img:rounded-2xl prose-img:shadow-lg
                    prose-blockquote:border-l-4 prose-blockquote:border-blue-500 prose-blockquote:bg-blue-50/50 prose-blockquote:py-2 prose-blockquote:px-4 prose-blockquote:not-italic prose-blockquote:rounded-r-lg"
                  dangerouslySetInnerHTML={{ __html: data.content }}
                />
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};


const BlogManager = () => {
  const [posts, setPosts] = useState([]);
  const [isEditing, setIsEditing] = useState(false);
  const [isPreviewOpen, setIsPreviewOpen] = useState(false);
  const [formData, setFormData] = useState({
    title: '',
    content: '',
    tags: '',
    image: '',
    slug: ''
  });
  const [searchQuery, setSearchQuery] = useState('');

  // Stats
  const wordCount = (formData.content || '').replace(/<[^>]*>/g, '').split(/\s+/).filter(w => w.length > 0).length || 0;
  const readTime = Math.ceil(wordCount / 200);

  useEffect(() => {
    fetchPosts();
  }, []);

  const fetchPosts = async () => {
    try {
      console.log('Fetching posts from /blog/admin/all...');
      const response = await api.get('/blog/admin/all');
      console.log('Admin API Response:', response);
      setPosts(response.data.data || []);
    } catch (error) {
      console.error('Error fetching posts (Admin):', error);
      // Fallback to public if admin route fails or is not ready
      try {
          console.log('Fetching posts from /blog (public fallback)...');
          const resPublic = await api.get('/blog');
          console.log('Public API Response:', resPublic);
          // Public API returns { status: 'success', data: { posts: [...], meta: ... } }
          const publicData = resPublic.data.data?.posts || [];
          console.log('Public Data Extracted:', publicData);
          setPosts(publicData);
      } catch (e) {
         console.error('Error fetching posts (Public):', e);
         setPosts([]);
         Swal.fire('Error', 'Failed to fetch posts', 'error');
      }
    }
  };

  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setFormData({ ...formData, [name]: value });
  };

  const handleContentChange = (value) => {
    setFormData({ ...formData, content: value });
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      // Prepare data for submission (convert tags back to array if needed, but backend now handles string too)
      // We send as is, backend handles it. Or we can split here.
      // Let's rely on backend fix, but for safety:
      const payload = { ...formData };
      
      if (formData.id) {
        await api.put(`/blog/admin/${formData.id}`, payload);
        Swal.fire('Success', 'Post updated successfully', 'success');
      } else {
        await api.post('/blog/admin', payload);
        Swal.fire('Success', 'Post created successfully', 'success');
      }
      setIsEditing(false);
      setFormData({ title: '', content: '', tags: '', image: '', slug: '' });
      fetchPosts();
    } catch (error) {
      console.error('Error saving post:', error);
      Swal.fire('Error', 'Failed to save post', 'error');
    }
  };

  const handleEdit = (post) => {
    // Ensure tags are converted to string for the input field
    const tagsString = Array.isArray(post.tags) ? post.tags.join(', ') : (post.tags || '');
    setFormData({ ...post, tags: tagsString });
    setIsEditing(true);
  };

  const handleDelete = async (id) => {
    const result = await Swal.fire({
      title: 'Are you sure?',
      text: "You won't be able to revert this!",
      icon: 'warning',
      showCancelButton: true,
      confirmButtonColor: '#d33',
      cancelButtonColor: '#3085d6',
      confirmButtonText: 'Yes, delete it!'
    });

    if (result.isConfirmed) {
      try {
        await api.delete(`/blog/admin/${id}`);
        Swal.fire('Deleted!', 'Your file has been deleted.', 'success');
        fetchPosts();
      } catch (error) {
        console.error('Error deleting post:', error);
        Swal.fire('Error', 'Failed to delete post', 'error');
      }
    }
  };

  const handleImageUpload = async (e) => {
    const file = e.target.files[0];
    if (!file) return;

    const formData = new FormData();
    formData.append('image', file);

    try {
      const response = await api.post('/blog/upload', formData, {
        headers: { 'Content-Type': 'multipart/form-data' }
      });
      setFormData(prev => ({ ...prev, image: response.data.imageUrl }));
    } catch (error) {
      console.error('Error uploading image:', error);
      Swal.fire('Error', 'Failed to upload image', 'error');
    }
  };

  // Filter posts
  const filteredPosts = posts.filter(post => 
    post.title?.toLowerCase().includes(searchQuery.toLowerCase()) ||
    (Array.isArray(post.tags) ? post.tags.join(' ') : (post.tags || '')).toLowerCase().includes(searchQuery.toLowerCase())
  );

  if (isEditing) {
    return (
      <div className="min-h-screen bg-slate-50 flex flex-col">
        {/* Editor Toolbar (Sticky) */}
        <div className="sticky top-0 z-40 bg-white border-b border-slate-200 px-6 py-3 flex items-center justify-between shadow-sm">
          <div className="flex items-center gap-4">
            <button 
              onClick={() => setIsEditing(false)}
              className="p-2 hover:bg-slate-100 rounded-full text-slate-500 transition-colors"
            >
              <FiArrowLeft size={24} />
            </button>
            <h1 className="text-xl font-bold text-slate-800">
              {formData.id ? 'Edit Post' : 'New Post'}
            </h1>
            <div className="h-6 w-px bg-slate-200 mx-2"></div>
            <div className="flex items-center gap-4 text-xs font-medium text-slate-500">
              <span className="flex items-center gap-1"><FiType /> {wordCount} words</span>
              <span className="flex items-center gap-1"><FiClock /> {readTime} min read</span>
            </div>
          </div>
          
          <div className="flex items-center gap-3">
             <button
              type="button"
              onClick={() => setIsPreviewOpen(true)}
              className="flex items-center gap-2 px-4 py-2 bg-slate-100 text-slate-700 rounded-lg hover:bg-slate-200 transition-all font-medium"
            >
              <FiEye /> Preview
            </button>
            <button
              onClick={handleSubmit}
              className="flex items-center gap-2 px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-all font-medium shadow-lg shadow-blue-600/20"
            >
              <FiSave /> {formData.id ? 'Update' : 'Publish'}
            </button>
          </div>
        </div>

        {/* Main Editor Area */}
        <div className="flex-1 max-w-7xl mx-auto w-full p-6 grid grid-cols-1 lg:grid-cols-3 gap-8">
          
          {/* Left: Main Content */}
          <div className="lg:col-span-2 space-y-6">
            <div className="bg-white rounded-2xl shadow-sm border border-slate-200 p-6">
              <input
                type="text"
                name="title"
                placeholder="Post Title"
                value={formData.title}
                onChange={handleInputChange}
                className="w-full text-4xl font-bold text-slate-800 placeholder-slate-300 border-none focus:ring-0 p-0 mb-6"
              />
              <div className="prose-editor">
                 <ReactQuill 
                  theme="snow" 
                  value={formData.content} 
                  onChange={handleContentChange}
                  className="h-[600px] mb-12"
                  modules={{
                    toolbar: [
                      [{ 'header': [1, 2, 3, false] }],
                      ['bold', 'italic', 'underline', 'strike', 'blockquote'],
                      [{'list': 'ordered'}, {'list': 'bullet'}],
                      ['link', 'image', 'code-block'],
                      ['clean']
                    ],
                  }}
                />
              </div>
            </div>
          </div>

          {/* Right: Settings */}
          <div className="space-y-6">
             {/* Publish Settings */}
            <div className="bg-white rounded-2xl shadow-sm border border-slate-200 p-6">
              <h3 className="font-bold text-slate-800 mb-4 flex items-center gap-2">
                <FiLayout className="text-blue-500" /> Post Settings
              </h3>
              
              <div className="space-y-4">
                <div>
                  <label className="block text-xs font-semibold text-slate-500 uppercase tracking-wider mb-2">URL Slug</label>
                  <input
                    type="text"
                    name="slug"
                    value={formData.slug}
                    onChange={handleInputChange}
                    placeholder="my-post-slug"
                    className="w-full px-4 py-2 bg-slate-50 border border-slate-200 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none transition-all text-sm"
                  />
                </div>
                
                <div>
                  <label className="block text-xs font-semibold text-slate-500 uppercase tracking-wider mb-2">Tags</label>
                  <input
                    type="text"
                    name="tags"
                    value={formData.tags}
                    onChange={handleInputChange}
                    placeholder="tech, life, coding"
                    className="w-full px-4 py-2 bg-slate-50 border border-slate-200 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none transition-all text-sm"
                  />
                  <div className="flex flex-wrap gap-2 mt-3">
                    {formData.tags && formData.tags.split(',').filter(t => t.trim()).map((tag, i) => (
                      <span key={i} className="px-2 py-1 bg-blue-50 text-blue-600 rounded-md text-xs font-medium">
                        #{tag.trim()}
                      </span>
                    ))}
                  </div>
                </div>
              </div>
            </div>

            {/* Featured Image */}
            <div className="bg-white rounded-2xl shadow-sm border border-slate-200 p-6">
              <h3 className="font-bold text-slate-800 mb-4 flex items-center gap-2">
                <FiImage className="text-purple-500" /> Featured Image
              </h3>
              
              <div className="w-full aspect-video bg-slate-50 border-2 border-dashed border-slate-300 rounded-xl overflow-hidden relative hover:border-blue-500 transition-colors group">
                {formData.image ? (
                  <>
                    <img src={formData.image} alt="Preview" className="w-full h-full object-cover" />
                    <div className="absolute inset-0 bg-black/40 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center">
                      <label className="cursor-pointer px-4 py-2 bg-white/20 backdrop-blur-md text-white rounded-lg hover:bg-white/30 transition-all font-medium">
                        Change Image
                        <input type="file" className="hidden" onChange={handleImageUpload} />
                      </label>
                    </div>
                  </>
                ) : (
                  <label className="absolute inset-0 flex flex-col items-center justify-center cursor-pointer">
                    <FiImage size={32} className="text-slate-300 mb-2" />
                    <span className="text-sm text-slate-400 font-medium">Click to upload image</span>
                    <input type="file" className="hidden" onChange={handleImageUpload} />
                  </label>
                )}
              </div>
              <input
                type="text"
                name="image"
                value={formData.image}
                onChange={handleInputChange}
                placeholder="Or paste image URL..."
                className="w-full mt-4 px-3 py-2 text-sm bg-slate-50 border border-slate-200 rounded-lg focus:ring-2 focus:ring-blue-500 outline-none"
              />
            </div>
          </div>
        </div>
        
        {/* Preview Modal */}
        <BlogPreviewModal 
          isOpen={isPreviewOpen} 
          onClose={() => setIsPreviewOpen(false)} 
          data={formData} 
        />
      </div>
    );
  }

  // Dashboard View (List of posts)
  return (
    <AdminLayout>
      <div className="space-y-6">
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 mb-8">
        <div>
          <h1 className="text-3xl font-bold text-slate-900">Blog Posts</h1>
          <p className="text-slate-500 mt-1">Manage and publish your content</p>
        </div>
        <button
          onClick={() => {
            setFormData({ title: '', content: '', tags: '', image: '', slug: '' });
            setIsEditing(true);
          }}
          className="flex items-center justify-center gap-2 px-6 py-3 bg-blue-600 text-white rounded-xl hover:bg-blue-700 transition-all shadow-lg shadow-blue-600/20 font-medium"
        >
          <FiPlus size={20} /> Create New Post
        </button>
      </div>

      {/* Search and Filters */}
      <div className="bg-white p-4 rounded-2xl shadow-sm border border-slate-200 mb-6 flex items-center gap-4">
        <FiSearch className="text-slate-400 ml-2" size={20} />
        <input 
          type="text" 
          placeholder="Search posts by title or tags..." 
          className="flex-1 bg-transparent border-none outline-none text-slate-700 placeholder-slate-400"
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
        />
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {filteredPosts.map((post) => (
          <div key={post.id} className="group bg-white rounded-2xl border border-slate-200 overflow-hidden hover:shadow-xl hover:border-blue-200 transition-all duration-300 flex flex-col h-full">
            <div className="aspect-video bg-slate-100 relative overflow-hidden">
              {post.image ? (
                <img src={post.image} alt={post.title} className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500" />
              ) : (
                <div className="w-full h-full flex items-center justify-center text-slate-300">
                  <FiImage size={40} />
                </div>
              )}
              <div className="absolute top-4 right-4 flex gap-2 opacity-0 group-hover:opacity-100 transition-opacity translate-y-2 group-hover:translate-y-0 duration-300">
                <button
                  onClick={() => handleEdit(post)}
                  className="p-2 bg-white/90 backdrop-blur text-blue-600 rounded-lg shadow-sm hover:bg-blue-50 transition-colors"
                  title="Edit"
                >
                  <FiEdit2 size={16} />
                </button>
                <button
                  onClick={() => handleDelete(post.id)}
                  className="p-2 bg-white/90 backdrop-blur text-red-500 rounded-lg shadow-sm hover:bg-red-50 transition-colors"
                  title="Delete"
                >
                  <FiTrash2 size={16} />
                </button>
              </div>
            </div>
            
            <div className="p-6 flex-1 flex flex-col">
              <div className="flex gap-2 mb-3">
                 {(() => {
                    const tagsArray = Array.isArray(post.tags) 
                      ? post.tags 
                      : (post.tags ? post.tags.split(',') : []);
                    
                    return (
                      <>
                        {tagsArray.slice(0, 2).map((tag, i) => (
                           <span key={i} className="text-[10px] font-bold uppercase tracking-wider text-blue-600 bg-blue-50 px-2 py-1 rounded-md">
                             {tag.trim()}
                           </span>
                        ))}
                        {tagsArray.length > 2 && (
                           <span className="text-[10px] font-bold uppercase tracking-wider text-slate-500 bg-slate-100 px-2 py-1 rounded-md">
                             +{tagsArray.length - 2}
                           </span>
                        )}
                      </>
                    );
                 })()}
              </div>
              <h3 className="font-bold text-lg text-slate-800 mb-2 line-clamp-2 group-hover:text-blue-600 transition-colors">
                {post.title}
              </h3>
              <p className="text-slate-500 text-sm line-clamp-3 mb-4 flex-1">
                {(post.content || '').replace(/<[^>]*>/g, '')}
              </p>
              <div className="pt-4 border-t border-slate-100 flex items-center justify-between text-xs text-slate-400 font-medium">
                 <span>{new Date().toLocaleDateString()}</span>
                 <span>Admin</span>
              </div>
            </div>
          </div>
        ))}
      </div>
      
      {filteredPosts.length === 0 && (
        <div className="text-center py-20">
          <div className="bg-slate-50 w-20 h-20 rounded-full flex items-center justify-center mx-auto mb-4">
            <FiLayout className="text-slate-300" size={32} />
          </div>
          <h3 className="text-lg font-semibold text-slate-700">No posts found</h3>
          <p className="text-slate-500">Create your first blog post to get started.</p>
        </div>
      )}
    </div>
    </AdminLayout>
  );
};

export default BlogManager;
