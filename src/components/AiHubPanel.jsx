import { useState } from "react";
import { Bot, Compass, ArrowUpRight, Sparkles, X, Cpu } from "lucide-react";
import "./AiHubPanel.css";

export default function AiHubPanel() {
  const [activeModal, setActiveModal] = useState(null);

  const handleOpenModal = (type) => {
    setActiveModal(type);
  };

  const handleCloseModal = () => {
    setActiveModal(null);
  };

  return (
    <>
      <div className="ai-hub-panel animate-fade-in-up">
        <div className="ai-hub-content">
          <div className="ai-hub-header">
            <div className="ai-hub-brand-group">
              <div className="ai-hub-icon-badge">
                <Cpu size={24} strokeWidth={2} />
              </div>
              <div className="ai-hub-titles">
                <div className="ai-hub-title-row">
                  <h2 className="ai-hub-title">AI Hub</h2>
                  <span className="ai-hub-tag">DUAL ENGINE</span>
                </div>
                <p className="ai-hub-subtitle">Career Intelligence Powered by AI</p>
              </div>
            </div>
            <button
              className="ai-hub-arrow-btn"
              onClick={() => handleOpenModal("overview")}
              title="Open AI Intelligence Hub"
              aria-label="Open AI Intelligence Hub"
            >
              <ArrowUpRight size={18} />
            </button>
          </div>

          <div className="ai-hub-actions">
            <button
              className="ai-hub-btn ai-hub-btn-twin"
              onClick={() => handleOpenModal("twin")}
            >
              <Bot size={18} />
              <span>Career Twin AI</span>
            </button>

            <button
              className="ai-hub-btn ai-hub-btn-gps"
              onClick={() => handleOpenModal("gps")}
            >
              <Compass size={18} />
              <span>Career GPS AI</span>
            </button>
          </div>
        </div>
      </div>

      {activeModal && (
        <div className="ai-hub-modal-overlay" onClick={handleCloseModal}>
          <div
            className="ai-hub-modal"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="ai-hub-modal-header">
              <div className="ai-hub-modal-title">
                {activeModal === "twin" && (
                  <>
                    <Bot size={20} style={{ color: "#38bdf8" }} />
                    <span>Career Twin AI</span>
                  </>
                )}
                {activeModal === "gps" && (
                  <>
                    <Compass size={20} style={{ color: "#e879f9" }} />
                    <span>Career GPS AI</span>
                  </>
                )}
                {activeModal === "overview" && (
                  <>
                    <Sparkles size={20} style={{ color: "#38bdf8" }} />
                    <span>AI Intelligence Hub</span>
                  </>
                )}
              </div>
              <button
                className="ai-hub-modal-close"
                onClick={handleCloseModal}
                aria-label="Close"
              >
                <X size={18} />
              </button>
            </div>

            <div className="ai-hub-modal-body">
              <div className="ai-hub-modal-chip">
                <Sparkles size={14} />
                <span>Dual Engine Active</span>
              </div>
              {activeModal === "twin" && (
                <p>
                  <strong>Career Twin AI</strong> analyzes background, skillset, and engagement patterns to generate personalized career simulations, skill gap recommendations, and alumni mentor matching.
                </p>
              )}
              {activeModal === "gps" && (
                <p>
                  <strong>Career GPS AI</strong> maps out optimal industry transition routes, salary benchmarks, and high-impact event recommendations based on real-time alumni career trajectories.
                </p>
              )}
              {activeModal === "overview" && (
                <p>
                  The <strong>AI Hub Engine</strong> leverages predictive analytics to connect alumni, students, and staff with real-time career intelligence and automated matching algorithms.
                </p>
              )}
            </div>
          </div>
        </div>
      )}
    </>
  );
}
