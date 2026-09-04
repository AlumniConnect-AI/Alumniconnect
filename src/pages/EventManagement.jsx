import { useState, useEffect, useMemo } from "react";
import {
    CalendarDays, Search, Trash2, Eye, X, MapPin, Users,
    Clock, Filter, Tag,
} from "lucide-react";
import { subscribeToEvents, deleteEvent } from "../services/firestoreService";
import LoadingSpinner from "../components/LoadingSpinner";
import "./EventManagement.css";

const EVENT_TYPES = ["all", "workshop", "webinar", "meetup", "conference", "other"];

export default function EventManagement() {
    const [events, setEvents] = useState([]);
    const [loading, setLoading] = useState(true);
    const [search, setSearch] = useState("");
    const [statusFilter, setStatusFilter] = useState("all");
    const [typeFilter, setTypeFilter] = useState("all");
    const [selectedEvent, setSelectedEvent] = useState(null);
    const [confirmDel, setConfirmDel] = useState(null);
    const [deleting, setDeleting] = useState(false);

    useEffect(() => {
        const unsub = subscribeToEvents((data) => { setEvents(data); setLoading(false); });
        return unsub;
    }, []);

    const enriched = useMemo(() => events.map((e) => {
        const raw = e.date;
        const dateObj = raw?.toDate ? raw.toDate() : new Date(raw);
        const isValid = dateObj && !isNaN(dateObj);
        const status = e.status || (isValid && dateObj > new Date() ? "upcoming" : "completed");
        const type = (e.type || e.eventType || "other").toLowerCase();
        return { ...e, dateObj, isValid, status, eventType: type };
    }), [events]);

    // Type breakdown
    const typeCounts = useMemo(() => {
        const c = {};
        enriched.forEach((e) => { c[e.eventType] = (c[e.eventType] || 0) + 1; });
        return c;
    }, [enriched]);

    const totalRSVP = useMemo(() => enriched.reduce((s, e) => s + (e.participants || e.rsvpCount || 0), 0), [enriched]);

    const filtered = useMemo(() => {
        const q = search.toLowerCase();
        return enriched.filter((e) => {
            const matchQ = !q || (e.title || "").toLowerCase().includes(q) || (e.location || "").toLowerCase().includes(q);
            const matchS = statusFilter === "all" || e.status === statusFilter;
            const matchT = typeFilter === "all" || e.eventType === typeFilter;
            return matchQ && matchS && matchT;
        });
    }, [enriched, search, statusFilter, typeFilter]);

    const handleDelete = async (id) => {
        setDeleting(true);
        try { await deleteEvent(id); } catch (e) { alert("Failed: " + e.message); }
        setDeleting(false); setConfirmDel(null);
    };

    if (loading) return <LoadingSpinner message="Loading events..." />;

    return (
        <div className="em-page">
            <div className="em-header animate-fade-in-up">
                <div>
                    <h2 className="em-title">Event Management</h2>
                    <p className="em-subtitle">{events.length} events · {totalRSVP} total RSVPs</p>
                </div>
            </div>

            {/* Type Breakdown */}
            <div className="em-type-cards stagger">
                <div className="em-type-card animate-fade-in-up em-type-total">
                    <CalendarDays size={18} />
                    <div className="em-type-val">{events.length}</div>
                    <div className="em-type-lbl">Total</div>
                </div>
                {Object.entries(typeCounts).slice(0, 5).map(([type, count]) => (
                    <div className="em-type-card animate-fade-in-up" key={type} onClick={() => setTypeFilter(type === typeFilter ? "all" : type)} style={{ cursor: "pointer" }}>
                        <Tag size={14} />
                        <div className="em-type-val">{count}</div>
                        <div className="em-type-lbl">{type}</div>
                    </div>
                ))}
            </div>

            {/* Controls */}
            <div className="em-controls animate-fade-in-up">
                <div className="sv-search-wrap">
                    <Search size={16} className="sv-search-icon" />
                    <input placeholder="Search events..." value={search} onChange={(e) => setSearch(e.target.value)} className="sv-search-input" />
                </div>
                <div className="sv-tabs">
                    <Filter size={14} style={{ color: "var(--text-muted)" }} />
                    {["all", "upcoming", "completed"].map((s) => (
                        <button key={s} className={`sv-tab ${statusFilter === s ? "active" : ""}`} onClick={() => setStatusFilter(s)}>
                            {s.charAt(0).toUpperCase() + s.slice(1)}
                        </button>
                    ))}
                </div>
            </div>

            {/* Event Grid */}
            <div className="em-grid stagger">
                {filtered.map((ev) => {
                    const dateStr = ev.isValid ? ev.dateObj.toLocaleDateString("en-US", { month: "short", day: "numeric", year: "numeric" }) : "—";
                    const rsvp = ev.participants || ev.rsvpCount || 0;

                    return (
                        <div className={`em-card animate-fade-in-up em-card--${ev.status}`} key={ev.id}>
                            <div className="em-card-top">
                                <div className="em-card-icon"><CalendarDays size={20} /></div>
                                <div className="em-card-badges">
                                    <span className={`em-status-badge ${ev.status}`}>{ev.status}</span>
                                    <span className="em-type-badge">{ev.eventType}</span>
                                </div>
                            </div>
                            <h3 className="em-card-title">{ev.title || "Untitled"}</h3>
                            <div className="em-card-meta">
                                <span><MapPin size={13} />{ev.location || "TBD"}</span>
                                <span><Clock size={13} />{dateStr}</span>
                            </div>
                            <div className="em-card-rsvp">
                                <Users size={14} /> <strong>{rsvp}</strong> RSVPs
                            </div>
                            <div className="jm-card-actions">
                                <button className="jm-action-btn jm-action-view" onClick={() => setSelectedEvent(ev)}><Eye size={15} /> View</button>
                                <button className="jm-action-btn jm-action-delete" onClick={() => setConfirmDel(ev.id)}><Trash2 size={15} /></button>
                            </div>
                        </div>
                    );
                })}
                {filtered.length === 0 && <p className="jm-empty">No events found</p>}
            </div>

            {/* Detail Modal */}
            {selectedEvent && (
                <div className="jm-modal-overlay" onClick={() => setSelectedEvent(null)}>
                    <div className="jm-modal animate-scale-in" onClick={(e) => e.stopPropagation()}>
                        <button className="jm-modal-close" onClick={() => setSelectedEvent(null)}><X size={18} /></button>
                        <div className="jm-modal-icon" style={{ background: "rgba(139,92,246,0.1)", color: "#8B5CF6" }}><CalendarDays size={24} /></div>
                        <h3 className="jm-modal-title">{selectedEvent.title}</h3>
                        <p className="jm-modal-company">{selectedEvent.eventType}</p>
                        <div className="jm-modal-grid">
                            <div className="jm-modal-item"><span className="jm-modal-label">Date</span><span className="jm-modal-value">{selectedEvent.isValid ? selectedEvent.dateObj.toLocaleDateString() : "—"}</span></div>
                            <div className="jm-modal-item"><span className="jm-modal-label">Location</span><span className="jm-modal-value">{selectedEvent.location || "TBD"}</span></div>
                            <div className="jm-modal-item"><span className="jm-modal-label">Organizer</span><span className="jm-modal-value">{selectedEvent.organizer || "N/A"}</span></div>
                            <div className="jm-modal-item"><span className="jm-modal-label">RSVPs</span><span className="jm-modal-value">{selectedEvent.participants || 0}</span></div>
                            <div className="jm-modal-item"><span className="jm-modal-label">Status</span><span className="jm-modal-value" style={{ textTransform: "capitalize" }}>{selectedEvent.status}</span></div>
                            <div className="jm-modal-item"><span className="jm-modal-label">Type</span><span className="jm-modal-value" style={{ textTransform: "capitalize" }}>{selectedEvent.eventType}</span></div>
                        </div>
                        {selectedEvent.description && <p className="jm-modal-desc">{selectedEvent.description}</p>}
                    </div>
                </div>
            )}

            {/* Delete Confirm */}
            {confirmDel && (
                <div className="jm-modal-overlay" onClick={() => !deleting && setConfirmDel(null)}>
                    <div className="jm-confirm animate-scale-in" onClick={(e) => e.stopPropagation()}>
                        <div className="jm-confirm-icon"><Trash2 size={28} /></div>
                        <h3>Delete this event?</h3>
                        <p>This action cannot be undone.</p>
                        <div className="jm-confirm-actions">
                            <button className="jm-confirm-cancel" onClick={() => setConfirmDel(null)} disabled={deleting}>Cancel</button>
                            <button className="jm-confirm-delete" onClick={() => handleDelete(confirmDel)} disabled={deleting}>
                                {deleting ? "Deleting..." : <><Trash2 size={15} /> Delete</>}
                            </button>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
}
