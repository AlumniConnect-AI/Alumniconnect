import "./LoadingSpinner.css";

export default function LoadingSpinner({ message = "Loading data..." }) {
    return (
        <div className="loading-container animate-fade-in">
            <div className="loading-spinner" />
            <p className="loading-message">{message}</p>
        </div>
    );
}
