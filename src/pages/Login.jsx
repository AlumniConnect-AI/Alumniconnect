import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { useAuth } from "../contexts/AuthContext";
import {
    Lock,
    Mail,
    Eye,
    EyeOff,
    Shield,
    GraduationCap,
    ArrowRight,
    AlertCircle,
} from "lucide-react";
import "./Login.css";

export default function Login() {
    const [email, setEmail] = useState("");
    const [password, setPassword] = useState("");
    const [showPw, setShowPw] = useState(false);
    const [error, setError] = useState("");
    const [loading, setLoading] = useState(false);
    const { login } = useAuth();
    const navigate = useNavigate();

    const handleSubmit = async (e) => {
        e.preventDefault();
        setError("");
        setLoading(true);

        try {
            await login(email, password);
            navigate("/dashboard");
        } catch (err) {
            console.error("Login error:", err.code, err.message);
            setError(
                err.code === "auth/invalid-credential"
                    ? "Invalid email or password"
                    : err.code === "auth/user-not-found"
                        ? "No account found with this email"
                        : err.code === "auth/wrong-password"
                            ? "Incorrect password"
                            : `Login failed: ${err.message}`
            );
        }
        setLoading(false);
    };

    return (
        <div className="login-page">
            {/* Decorative background elements */}
            <div className="login-bg">
                <div className="login-bg-circle c1" />
                <div className="login-bg-circle c2" />
                <div className="login-bg-circle c3" />
                <div className="login-bg-grid" />
            </div>

            <div className="login-container animate-scale-in">
                {/* Left branding panel */}
                <div className="login-brand">
                    <div className="login-brand-content">
                        <div className="login-logo">
                            <div className="login-logo-icon">
                                <GraduationCap size={32} strokeWidth={2} />
                            </div>
                            <span className="login-logo-text">AlumniConnect</span>
                        </div>

                        <h1 className="login-brand-title">Admin Panel</h1>
                        <p className="login-brand-desc">
                            Centralized governance and analytics for the AlumniConnect
                            ecosystem. Monitor alumni engagement, moderate content, and drive
                            institutional growth.
                        </p>

                        <div className="login-features">
                            <div className="login-feature">
                                <div className="login-feature-dot" />
                                <span>Real-time analytics dashboard</span>
                            </div>
                            <div className="login-feature">
                                <div className="login-feature-dot" />
                                <span>Alumni data management</span>
                            </div>
                            <div className="login-feature">
                                <div className="login-feature-dot" />
                                <span>Job & event moderation</span>
                            </div>
                            <div className="login-feature">
                                <div className="login-feature-dot" />
                                <span>Engagement insights & reports</span>
                            </div>
                        </div>
                    </div>

                    <div className="login-brand-footer">
                        <Shield size={14} />
                        <span>Secured with Firebase Authentication</span>
                    </div>
                </div>

                {/* Right form panel */}
                <div className="login-form-panel">
                    <div className="login-form-header">
                        <h2>Welcome back</h2>
                        <p>Sign in to your admin account</p>
                    </div>

                    {error && (
                        <div className="login-error animate-fade-in-down">
                            <AlertCircle size={16} />
                            <span>{error}</span>
                        </div>
                    )}

                    <form onSubmit={handleSubmit} className="login-form" id="login-form">
                        <div className="login-field">
                            <label htmlFor="email">Email address</label>
                            <div className="login-input-wrap">
                                <Mail size={18} className="login-input-icon" />
                                <input
                                    id="email"
                                    type="email"
                                    placeholder="admin@alumniconnect.com"
                                    value={email}
                                    onChange={(e) => setEmail(e.target.value)}
                                    required
                                    autoComplete="email"
                                />
                            </div>
                        </div>

                        <div className="login-field">
                            <label htmlFor="password">Password</label>
                            <div className="login-input-wrap">
                                <Lock size={18} className="login-input-icon" />
                                <input
                                    id="password"
                                    type={showPw ? "text" : "password"}
                                    placeholder="Enter your password"
                                    value={password}
                                    onChange={(e) => setPassword(e.target.value)}
                                    required
                                    autoComplete="current-password"
                                />
                                <button
                                    type="button"
                                    className="login-pw-toggle"
                                    onClick={() => setShowPw(!showPw)}
                                    aria-label="Toggle password visibility"
                                >
                                    {showPw ? <EyeOff size={18} /> : <Eye size={18} />}
                                </button>
                            </div>
                        </div>

                        <button
                            type="submit"
                            className="login-submit"
                            id="login-submit"
                            disabled={loading}
                        >
                            {loading ? (
                                <span className="login-spinner" />
                            ) : (
                                <>
                                    Sign In
                                    <ArrowRight size={18} />
                                </>
                            )}
                        </button>
                    </form>

                    <div className="login-demo-hint">
                        <p>
                            <strong>Sign in with your Firebase admin account</strong>
                        </p>
                    </div>
                </div>
            </div>
        </div>
    );
}
