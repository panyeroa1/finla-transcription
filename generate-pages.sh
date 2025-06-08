```bash
#!/bin/bash

# Define the main application directory
APP_DIR="transcription-app"

echo "Creating main application directory: $APP_DIR"
mkdir -p "$APP_DIR"
cd "$APP_DIR" || { echo "Failed to change directory to $APP_DIR. Exiting."; exit 1; }

echo "Creating subdirectories..."
mkdir -p frontend/{css,js}
mkdir -p backend/{src/models,src/services,src/utils}
mkdir -p infrastructure

echo "Directory structure created."

echo "Creating frontend files (HTML, CSS, JS)..."

# frontend/index.html
cat << 'EOF' > frontend/index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Finla.ai - Advanced Transcription UI</title>
    <link rel="stylesheet" href="css/style.css">
</head>
<body>
    <div id="loadingOverlay">
        <div class="spinner"></div>
        <p id="loadingMessage">Processing audio...</p>
    </div>

    <header class="app-header">
        <img src="https://finla.ai/img/logo_text.svg" alt="Finla.ai Logo" class="logo-img">
        <div class="theme-switch-wrapper">
            <label for="themeToggleCheckbox" style="color: var(--text-secondary); font-size: 0.8rem; margin-right: 0.5rem;">Dark Mode</label>
            <label class="theme-switch" for="themeToggleCheckbox">
                <input type="checkbox" id="themeToggleCheckbox" />
                <div class="slider"></div>
            </label>
        </div>
    </header>

    <div class="container">
        <main class="main-content">
            <div class="controls-column">
                <section class="card controls-area">
                    <h2 class="card-title">Transcription Controls</h2>
                    <div class="control-group">
                        <label for="sttServiceSelect">STT Service</label>
                        <select id="sttServiceSelect">
                            <option value="openai_whisper">OpenAI Whisper</option>
                            <option value="deepgram_nova">Deepgram (Nova-3)</option>
                            <option value="google_gemini_audio">Google Gemini (Audio Description)</option>
                        </select>
                    </div>
                    <div class="button-group">
                        <button id="startRecordBtn" class="btn btn-primary">Start Recording</button>
                        <div class="button-row">
                            <button id="pauseRecordBtn" class="btn btn-warning disabled" disabled>Pause</button>
                            <button id="resumeRecordBtn" class="btn btn-primary disabled" disabled>Resume</button>
                        </div>
                        <button id="stopRecordBtn" class="btn btn-secondary disabled" disabled>Stop & Transcribe</button>
                        <div class="upload-group">
                            <button id="uploadAudioBtn" class="btn btn-upload">Upload Audio File</button>
                            <input type="file" id="audioFileUpload" accept="audio/*,video/webm,audio/webm,audio/mp3,audio/mp4,audio/mpeg,audio/mpga,audio/m4a,audio/wav,audio/ogg">
                            <div id="fileNameDisplay">No file selected.</div>
                        </div>
                    </div>
                     <div class="topic-focus-group control-group">
                        <h3 class="card-title">Topic Focus (Keywords)</h3>
                        <div class="checkbox-group">
                            <div class="checkbox-item">
                                <input type="checkbox" id="topicMedical" name="topicFocus" value="medical">
                                <label for="topicMedical">Medical (Singapore)</label>
                            </div>
                            <div class="checkbox-item">
                                <input type="checkbox" id="topicInsurance" name="topicFocus" value="insurance">
                                <label for="topicInsurance">Insurance (Singapore)</label>
                            </div>
                            <div class="checkbox-item">
                                <input type="checkbox" id="topicGeneral" name="topicFocus" value="general" checked>
                                <label for="topicGeneral">General</label>
                            </div>
                        </div>
                         <p class="placeholder-note" style="font-size:0.75rem; margin-top:0.3rem;">For Deepgram, these selected topics are sent as hints, and its native topic detection is also enabled. For OpenAI and Google Gemini, topics are based on client-side keyword matching of selected focus areas from the generated text.</p>
                    </div>
                </section>

                <section class="card status-area">
                    <h2 class="card-title">Status</h2>
                    <div class="status-display-container">
                        <div id="statusDisplayText" class="status-display-text">Idle. Ready to record or upload.</div>
                    </div>
                    <canvas id="audioWaveformCanvas"></canvas>
                </section>
            </div>

            <div class="transcript-column-wrapper output-column">
                <section class="card">
                    <h2 class="card-title">Raw Transcription</h2>
                    <textarea id="transcriptOutputConvo" class="output-area" placeholder="Full conversation text will appear here.&#10;&#10;OpenAI Whisper: Excellent accuracy for general speech and many languages.&#10;&#10;Deepgram Nova-3: Offers superior speed, high accuracy in diverse audio conditions, advanced diarization, smart formatting, and native topic detection. Ideal for real-time applications and complex audio.&#10;&#10;Google Gemini (Audio Description): Provides a descriptive summary of audio content, including any transcribed speech, and multimodal understanding. Great for rich content analysis beyond just transcription." readonly></textarea>
                </section>
                 <section class="card">
                    <h2 class="card-title">Polished Note</h2>
                    <div id="polishedNote" class="output-area" contenteditable="false" placeholder="A polished, formatted summary will appear here for Google Gemini transcripts."></div>
                </section>
                <section class="card">
                    <h2 class="card-title">Multispeaker Output</h2>
                    <textarea id="transcriptOutputMultispeaker" class="output-area" placeholder="[Speaker X: 0.00s - 5.32s] Segment text...&#10;&#10;Deepgram: Provides robust speaker labels and precise time segments.&#10;&#10;OpenAI Whisper: Provides time segments but does not offer speaker labels.&#10;&#10;Google Gemini (Audio Description): Does not provide segments or speaker labels." readonly></textarea>
                    <p class="placeholder-note">Note: Deepgram provides speaker labels and time segments. OpenAI Whisper output here will be time-segmented only. Google Gemini (audio description) does not provide segments or speaker labels.</p>
                </section>
                <section class="card">
                    <h2 class="card-title">Detected Topics</h2>
                    <ul id="detectedTopicsList" class="empty">
                        <li>No topics detected yet.</li>
                    </ul>
                     <p class="placeholder-note">Note: Deepgram provides its own topic detection. For OpenAI and Google Gemini, topics are based on client-side keyword matching of selected focus areas from the generated text.</p>
                </section>
            </div>
        </main>
        <section class="card recorded-audio-list-section">
            <h2 class="card-title">Recorded Audio History</h2>
            <ul id="recordedAudioList">
                <li class="empty-list-message">No recordings yet.</li>
            </ul>
        </section>
    </div>

    <footer class="app-footer">
        <p>© <span id="currentYear"></span> Finla.ai. For local testing and demonstration.</p>
    </footer>

    <script src="js/app.js"></script>
</body>
</html>
EOF

# frontend/css/style.css
cat << 'EOF' > frontend/css/style.css
/* CSS Variables for Theming and Consistency */
:root {
    --font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif, "Apple Color Emoji", "Segoe UI Emoji", "Segoe UI Symbol";
    
    /* Finla.ai Inspired Colors */
    --finla-dark-blue: #1E3A8A; 
    --finla-light-blue-accent: #60A5FA;
    --finla-green-accent: #34D399;

    /* Light Theme (Default) */
    --bg-primary-light: #F7F9FC;
    --bg-secondary-light: #FFFFFF;
    --text-primary-light: #222F3E;
    --text-secondary-light: #576574;
    --accent-primary-light: var(--finla-dark-blue);
    --accent-secondary-light: #1C3274;
    --border-color-light: #DDE3EA;
    --shadow-color-light: rgba(30, 58, 138, 0.08);
    --error-color-light: #EF4444;
    --success-color-light: #10B981;
    --output-bg-light: #FDFEFE;


    /* Dark Theme */
    --bg-primary-dark: #161A1D;
    --bg-secondary-dark: #1F2428;
    --text-primary-dark: #E5E7EB;
    --text-secondary-dark: #9CA3AF;
    --accent-primary-dark: var(--finla-light-blue-accent);
    --accent-secondary-dark: #3B82F6;
    --border-color-dark: #374151;
    --shadow-color-dark: rgba(0, 0, 0, 0.2);
    --error-color-dark: #F87171;
    --success-color-dark: #34D399;
    --output-bg-dark: #24292E;


    /* Universal Variables */
    --border-radius: 8px;
    --transition-speed: 0.25s;
    --button-padding: 0.75em 1.4em;
}

/* Initialize theme variables */
body {
    --bg-primary: var(--bg-primary-light);
    --bg-secondary: var(--bg-secondary-light);
    --text-primary: var(--text-primary-light);
    --text-secondary: var(--text-secondary-light);
    --accent-primary: var(--accent-primary-light);
    --accent-secondary: var(--accent-secondary-light);
    --border-color: var(--border-color-light);
    --shadow-color: var(--shadow-color-light);
    --error-color: var(--error-color-light);
    --success-color: var(--success-color-light);
    --output-bg: var(--output-bg-light);
}

body.dark-theme {
    --bg-primary: var(--bg-primary-dark);
    --bg-secondary: var(--bg-secondary-dark);
    --text-primary: var(--text-primary-dark);
    --text-secondary: var(--text-secondary-dark);
    --accent-primary: var(--accent-primary-dark);
    --accent-secondary: var(--accent-secondary-dark);
    --border-color: var(--border-color-dark);
    --shadow-color: var(--shadow-color-dark);
    --error-color: var(--error-color-dark);
    --success-color: var(--success-color-dark);
    --output-bg: var(--output-bg-dark);
}

/* Global Styles */
*, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
html { scroll-behavior: smooth; }
body {
    font-family: var(--font-family); background-color: var(--bg-primary); color: var(--text-primary);
    transition: background-color var(--transition-speed) ease, color var(--transition-speed) ease;
    font-size: 16px; line-height: 1.6;
}
.container { width: 100%; max-width: 1200px; margin: 0 auto; padding: 1rem; }

/* Header */
.app-header {
    display: flex; justify-content: space-between; align-items: center; padding: 0.75rem 1rem;
    background-color: var(--bg-secondary); box-shadow: 0 2px 8px var(--shadow-color);
    border-bottom: 1px solid var(--border-color); position: sticky; top: 0; z-index: 1000;
    transition: background-color var(--transition-speed) ease, border-color var(--transition-speed) ease;
}
.logo-img { height: 32px; width: auto; display: block; }
.theme-switch-wrapper { display: flex; align-items: center; }
.theme-switch { display: inline-block; height: 26px; position: relative; width: 50px; margin-left: 0.5rem; }
.theme-switch input { display:none; }
.slider {
    background-color: #B0B0B0; bottom: 0; cursor: pointer; left: 0; position: absolute; right: 0; top: 0;
    transition: .4s; border-radius: 26px;
}
.slider:before {
    background-color: #fff; bottom: 3px; content: ""; height: 20px; left: 3px; position: absolute;
    transition: .4s; width: 20px; border-radius: 50%; box-shadow: 0 1px 3px rgba(0,0,0,0.2);
}
input:checked + .slider { background-color: var(--accent-primary); }
input:checked + .slider:before { transform: translateX(24px); }
.main-content { padding-top: 1.5rem; display: flex; flex-direction: column; gap: 1.5rem; }
.card {
    background-color: var(--bg-secondary); border-radius: var(--border-radius); padding: 1.5rem;
    box-shadow: 0 4px 12px var(--shadow-color); border: 1px solid var(--border-color);
    transition: background-color var(--transition-speed) ease, border-color var(--transition-speed) ease, box-shadow var(--transition-speed) ease;
}
.card-title { font-size: 1.1rem; font-weight: 600; margin-bottom: 1rem; color: var(--text-primary); }
.controls-area .control-group { margin-bottom: 1rem; }
.controls-area label { display: block; font-size: 0.875rem; color: var(--text-secondary); margin-bottom: 0.4rem; }
.controls-area select, .status-display-text { 
    width: 100%; padding: 0.65rem 0.75rem; border-radius: var(--border-radius); border: 1px solid var(--border-color);
    background-color: var(--bg-primary); color: var(--text-primary); font-size: 0.9rem;
    transition: border-color var(--transition-speed) ease, background-color var(--transition-speed) ease, color var(--transition-speed) ease;
}
.controls-area select:focus { outline: none; border-color: var(--accent-primary); box-shadow: 0 0 0 2px var(--accent-primary-light); }
body.dark-theme .controls-area select:focus { box-shadow: 0 0 0 2px var(--accent-primary-dark); }

.topic-focus-group { margin-top: 1rem; }
.topic-focus-group .card-title { margin-bottom: 0.5rem; font-size:1rem; }
.topic-focus-group .checkbox-group { display: flex; flex-direction: column; gap: 0.5rem; }
.topic-focus-group .checkbox-item { display: flex; align-items: center; }
.topic-focus-group .checkbox-item input[type="checkbox"] { margin-right: 0.5rem; width: 16px; height: 16px; accent-color: var(--accent-primary); }
.topic-focus-group .checkbox-item label { font-size: 0.9rem; color: var(--text-primary); margin-bottom: 0; }


.status-display-container { opacity: 1; transform: translateY(0); transition: opacity var(--transition-speed) ease, transform var(--transition-speed) ease; }
.status-display-container.hidden { opacity: 0; transform: translateY(-10px); height: 0; overflow: hidden; }
.status-display-text {
     min-height: 38px; display: flex; align-items: center; font-style: italic; margin-bottom: 0.5rem;
}
.status-display-text.error { color: var(--error-color); font-weight: 500; border-left: 3px solid var(--error-color); padding-left: 0.5rem;}
.status-display-text.success { color: var(--success-color); font-weight: 500; border-left: 3px solid var(--success-color); padding-left: 0.5rem;}
#audioWaveformCanvas {
    width: 100%; height: 60px; background-color: var(--output-bg);
    border-radius: calc(var(--border-radius) / 2); display: none; margin-top: 0.5rem; border: 1px solid var(--border-color);
}
.button-group { display: flex; flex-direction: column; gap: 0.75rem; }
.button-row { display: flex; gap: 0.5rem; } 
.button-row .btn { flex: 1; } 

.btn {
    padding: var(--button-padding); font-size: 0.95rem; font-weight: 500; border: none;
    border-radius: var(--border-radius); cursor: pointer;
    transition: background-color var(--transition-speed) ease, transform 0.1s ease, box-shadow var(--transition-speed) ease;
    text-align: center; width: 100%;
    box-shadow: 0 2px 4px var(--shadow-color-light);
}
body.dark-theme .btn { box-shadow: 0 2px 4px var(--shadow-color-dark); }
.btn-primary { background-color: var(--accent-primary); color: white; }
.btn-primary:hover:not(:disabled) { background-color: var(--accent-secondary); box-shadow: 0 4px 8px var(--shadow-color-light); }
body.dark-theme .btn-primary:hover:not(:disabled) { box-shadow: 0 4px 8px var(--shadow-color-dark); }
.btn-secondary { background-color: var(--bg-secondary); color: var(--accent-primary); border: 1.5px solid var(--accent-primary); }
.btn-secondary:hover:not(:disabled) { background-color: var(--accent-primary); color: white; box-shadow: 0 4px 8px var(--shadow-color-light); }
body.dark-theme .btn-secondary:hover:not(:disabled) { background-color: var(--accent-primary); color: white; box-shadow: 0 4-box-shadow: 0 4px 8px var(--shadow-color-dark); }
.btn-warning { background-color: #F59E0B; color: white; } 
.btn-warning:hover:not(:disabled) { background-color: #D97706; } 

.btn:active:not(:disabled) { transform: scale(0.98); box-shadow: 0 1px 2px var(--shadow-color-light); }
body.dark-theme .btn:active:not(:disabled) { box-shadow: 0 1px 2px var(--shadow-color-dark); }
.btn.disabled, .btn:disabled {
    background-color: var(--text-secondary-light) !important; color: var(--bg-secondary-light) !important;
    cursor: not-allowed !important; opacity: 0.5 !important; border-color: var(--text-secondary-light) !important;
    box-shadow: none !important;
}
body.dark-theme .btn.disabled, body.dark-theme .btn:disabled {
     background-color: var(--text-secondary-dark) !important; color: var(--bg-secondary-dark) !important;
     border-color: var(--text-secondary-dark) !important;
}
.upload-group { margin-top: 0.75rem; }
#audioFileUpload { display: none; }
.btn-upload { background-color: var(--finla-green-accent); color: white; }
.btn-upload:hover:not(:disabled) { background-color: #25a575; box-shadow: 0 4px 8px var(--shadow-color-light);}
body.dark-theme .btn-upload:hover:not(:disabled) { box-shadow: 0 4px 8px var(--shadow-color-dark); }
#fileNameDisplay { font-size: 0.8rem; color: var(--text-secondary); margin-top: 0.4rem; text-align: center; word-break: break-all; }
.output-column { display: flex; flex-direction: column; gap: 1.5rem; }
.output-area {
    width: 100%; min-height: 120px; padding: 0.75rem 1rem; border-radius: var(--border-radius);
    border: 1px solid var(--border-color); background-color: var(--output-bg); color: var(--text-primary);
    font-family: 'SFMono-Regular', Consolas, 'Liberation Mono', Menlo, Courier, monospace;
    font-size: 0.875rem; line-height: 1.6; resize: vertical;
    white-space: pre-wrap; word-wrap: break-word;
}
.output-area:focus { outline: none; border-color: var(--accent-primary); box-shadow: 0 0 0 2px var(--accent-primary-light); }
body.dark-theme .output-area:focus { box-shadow: 0 0 0 2px var(--accent-primary-dark); }

#detectedTopicsList { list-style-type: none; padding-left: 0; }
#detectedTopicsList li {
    background-color: var(--bg-primary); padding: 0.5rem 0.75rem; border-radius: calc(var(--border-radius) / 2);
    margin-bottom: 0.5rem; border: 1px solid var(--border-color); font-size: 0.9rem;
    color: var(--text-primary);
}
 #detectedTopicsList li:last-child { margin-bottom: 0; }
 #detectedTopicsList.empty { font-style: italic; color: var(--text-secondary); }
 .placeholder-note { font-size: 0.8rem; color: var(--text-secondary); margin-top: 0.5rem; font-style: italic;}


@media (min-width: 768px) {
    .container { padding: 1.5rem 2rem; }
    .main-content { flex-direction: row; align-items: flex-start; }
    .controls-column { flex: 0 0 320px; max-width: 320px; display: flex; flex-direction: column; gap: 1.5rem; }
    .controls-column .card { width: 100%; }
    .transcript-column-wrapper { flex: 1; min-width: 0; }
}
.app-footer {
    text-align: center; padding: 1.5rem 1rem; color: var(--text-secondary); font-size: 0.875rem;
    border-top: 1px solid var(--border-color); margin-top: 2rem;
}
#loadingOverlay {
    position: fixed; top: 0; left: 0; width: 100%; height: 100%;
    background-color: rgba(0, 0, 0, 0.6);
    display: flex; flex-direction: column; justify-content: center; align-items: center;
    z-index: 2000; color: white; font-size: 1.2rem; text-align: center;
    opacity: 0; visibility: hidden; transition: opacity 0.3s ease, visibility 0.3s ease;
}
#loadingOverlay.visible { opacity: 1; visibility: visible; }
.spinner {
    border: 5px solid #f3f3f3; border-top: 5px solid var(--accent-primary-dark);
    border-radius: 50%; width: 50px; height: 50px;
    animation: spin 1s linear infinite; margin-bottom: 1rem;
}
@keyframes spin { 0% { transform: rotate(0deg); } 100% { transform: rotate(360deg); } }

.btn.animating {
    animation: btn-pulse-border 1.5s infinite, btn-pulse-bg 1.5s infinite;
}
@keyframes btn-pulse-border {
    0% { border-color: var(--accent-primary); }
    50% { border-color: var(--accent-secondary); }
    100% { border-color: var(--accent-primary); }
}
@keyframes btn-pulse-bg {
    0% { background-color: var(--accent-primary); }
    50% { background-color: var(--accent-secondary); }
    100% { background-color: var(--accent-primary); }
}
.btn-primary.animating {}
.btn-secondary.animating { 
    background-color: var(--accent-primary); 
    color: white; 
    animation: btn-pulse-border 1.5s infinite, btn-pulse-bg 1.5s infinite; 
}
.btn-upload.animating {
    animation: btn-pulse-border-upload 1.5s infinite, btn-pulse-bg-upload 1.5s infinite;
}
@keyframes btn-pulse-border-upload {
    0% { border-color: var(--finla-green-accent); }
    50% { border-color: #25a575; }
    100% { border-color: var(--finla-green-accent); }
}
@keyframes btn-pulse-bg-upload {
    0% { background-color: var(--finla-green-accent); }
    50% { background-color: #25a575; }
    100% { background-color: var(--finla-green-accent); }
}
EOF

# frontend/js/app.js
cat << 'EOF' > frontend/js/app.js
// frontend/js/app.js

// Simple markdown to HTML conversion (for demo purposes only)
// In a real project, you would use a proper markdown parser like 'marked.js'
// if it's not loaded globally.
function simpleMarkdownToHtml(markdown) {
    if (!markdown) return '';

    let html = markdown;
    // Handle paragraphs (double line breaks)
    html = html.split('\n\n').map(p => {
        // Handle bold (**text**)
        let para = p.replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>');
        // Handle italic (*text*)
        para = para.replace(/\*(.*?)\*/g, '<em>$1</em>');
        // Handle headings (h1, h2, h3)
        para = para.replace(/^### (.*$)/gim, '<h3>$1</h3>');
        para = para.replace(/^## (.*$)/gim, '<h2>$1</h2>');
        para = para.replace(/^# (.*$)/gim, '<h1>$1</h1>');
        // Handle unordered lists (lines starting with - or *)
        const listItems = para.split('\n').map(line => {
            if (line.trim().startsWith('- ') || line.trim().startsWith('* ')) {
                return `<li>${line.trim().substring(2).trim()}</li>`;
            }
            return line;
        });
        if (listItems.some(item => item.includes('<li>'))) {
            // If there are list items, wrap them in <ul> and non-list items in <p>
            let finalHtml = '';
            let inList = false;
            for (const item of listItems) {
                if (item.includes('<li>')) {
                    if (!inList) {
                        finalHtml += '<ul>';
                        inList = true;
                    }
                    finalHtml += item;
                } else {
                    if (inList) {
                        finalHtml += '</ul>';
                        inList = false;
                    }
                    finalHtml += `<p>${item}</p>`;
                }
            }
            if (inList) {
                finalHtml += '</ul>';
            }
            return finalHtml;
        }

        return `<p>${para}</p>`;
    }).join('');

    return html;
}


document.addEventListener('DOMContentLoaded', () => {
    // --- IMPORTANT: Backend API Endpoint ---
    // During local development, this might be http://localhost:3000 (default Express port)
    // In production on AWS, this will be your EC2 instance's public IP or domain name.
    const BACKEND_API_BASE_URL = window.location.origin.includes("file://") ? "http://localhost:3000" : window.location.origin;

    const loadingOverlay = document.getElementById('loadingOverlay');
    const loadingMessage = document.getElementById('loadingMessage');
    const themeToggleCheckbox = document.getElementById('themeToggleCheckbox');
    const statusDisplayText = document.getElementById('statusDisplayText');
    const startRecordBtn = document.getElementById('startRecordBtn');
    const pauseRecordBtn = document.getElementById('pauseRecordBtn');
    const resumeRecordBtn = document.getElementById('resumeRecordBtn');
    const stopRecordBtn = document.getElementById('stopRecordBtn');
    const sttServiceSelect = document.getElementById('sttServiceSelect'); 
    
    const transcriptOutputConvo = document.getElementById('transcriptOutputConvo');
    const polishedNoteOutput = document.getElementById('polishedNote'); // Reference to new polished note div
    const transcriptOutputMultispeaker = document.getElementById('transcriptOutputMultispeaker'); 
    const detectedTopicsList = document.getElementById('detectedTopicsList'); 

    const topicMedicalCheckbox = document.getElementById('topicMedical');
    const topicInsuranceCheckbox = document.getElementById('topicInsurance');
    const topicGeneralCheckbox = document.getElementById('topicGeneral');

    const uploadAudioBtn = document.getElementById('uploadAudioBtn');
    const audioFileUpload = document.getElementById('audioFileUpload');
    const fileNameDisplay = document.getElementById('fileNameDisplay');
    
    const waveformCanvas = document.getElementById('audioWaveformCanvas');
    const waveformCtx = waveformCanvas.getContext('2d');
    
    const recordedAudioList = document.getElementById('recordedAudioList'); // New element for audio history

    let audioContext; 
    let vadAnalyserNode; 
    let vadProcessorNode; 
    let mediaStreamSourceForWaveform;
    let mediaStreamSourceForVAD; 
    let analyserForWaveform;
    let dataArrayForWaveform;
    let animationFrameId;

    let mediaRecorder;
    let allRecordedBlobs = []; 
    let currentStream = null; 
    let recordingState = 'idle';

    // IndexedDB for local caching (client-side only, independent of backend DB)
    const DB_NAME = 'FinlaAudioDB_App'; // Renamed to be more generic
    const STORE_NAME = 'audioFiles';
    let db;

    const VAD_SILENCE_THRESHOLD = 0.01; 
    const VAD_MIN_SPEECH_DURATION_MS = 200;   
    let vadIsSpeaking = false;
    let vadSpeechStartTime = 0;
    let activeSpeechSegments = []; 

    // Client-side topic keywords for OpenAI/Gemini keyword matching fallback
    const TOPIC_KEYWORDS_LOCAL = { 
        medical: [
            'doctor', 'clinic', 'hospital', 'polyclinic', 'singhealth', 'nuhs', 'healthhub', 'medisave', 'medishield', 
            'appointment', 'prescription', 'diagnosis', 'treatment', 'referral', 'medical certificate', 'mc', 
            'vaccination', 'health screening', 'physiotherapy', 'ward', 'icu', 'a&e', 'emergency', 'specialist',
            'general practitioner', 'gp', 'pharmacy', 'medication', 'symptom', 'illness', 'disease', 'insurance claim health',
            'integrated shield plan', 'careshield'
        ],
        insurance: [ 
            'insurance', 'policy', 'premium', 'coverage', 'claim', 'underwriting', 'beneficiary', 'sum assured', 
            'life insurance', 'health insurance', 'general insurance', 'car insurance', 'travel insurance', 'critical illness',
            'disability income', 'investment-linked policy', 'ilp', 'cpfis', 'agent', 'broker', 'insurer', 'prudential',
            'aia', 'great eastern', 'income', 'manulife', 'aviva', 'singlife', 'policyholder', 'rider', 'term life', 'whole life',
            'endowment', 'annuity', 'dependants protection scheme', 'dps', 'fire insurance'
        ]
    };

    // Initialize IndexedDB for local audio storage
    function initDB() { 
         return new Promise((resolve, reject) => {
            const request = indexedDB.open(DB_NAME, 1);
            request.onerror = event => {
                console.error("IndexedDB error:", event.target.errorCode, event.target.error);
                reject("IndexedDB error: " + event.target.errorCode);
            };
            request.onsuccess = event => {
                db = event.target.result;
                loadAndRenderRecordedAudio(); // Load existing recordings on DB ready
                resolve(db);
            };
            request.onupgradeneeded = event => {
                const store = event.target.result.createObjectStore(STORE_NAME, { keyPath: 'id', autoIncrement: true });
                store.createIndex('name', 'name', { unique: false });
                store.createIndex('timestamp', 'timestamp', { unique: false });
            };
        });
    }

    // Save audio Blob to IndexedDB
    async function saveAudioToDB(blob, name) { 
         if (!db) {
            try {
                await initDB(); 
                if(!db) { 
                     console.error("DB not initialized for saving, and re-init failed.");
                     updateStatus("Error: DB not ready for saving audio.", "error");
                     return;
                }
            } catch (e) {
                console.error("DB initialization failed during save attempt:", e);
                updateStatus("Error: DB not ready for saving audio.", "error");
                return;
            }
        }
        return new Promise((resolve, reject) => {
            const transaction = db.transaction([STORE_NAME], 'readwrite');
            const store = transaction.objectStore(STORE_NAME);
            const audioRecord = {
                name: name,
                blob: blob,
                timestamp: new Date().toISOString()
            };
            const request = store.add(audioRecord);
            request.onsuccess = () => {
                console.log(`Audio "${name}" saved to IndexedDB.`);
                loadAndRenderRecordedAudio(); // Refresh the list after saving
                resolve(request.result); 
            };
            request.onerror = event => {
                console.error("Error saving audio to IndexedDB:", event.target.error);
                updateStatus(`Error saving audio to local DB: ${event.target.error.message}`, "error");
                reject(event.target.error);
            };
        });
    }

    // Initialize IndexedDB on load
    initDB().then(() => console.log("IndexedDB initialized successfully."))
            .catch(err => console.error("Failed to initialize IndexedDB:", err));

    // Set current year in footer
    document.getElementById('currentYear').textContent = new Date().getFullYear();

    // Show/hide loading overlay with custom message
    function showLoading(context = "Processing") { 
        if (context === "recording_start") {
            return; // Don't show overlay for mere recording start
        }
        let message;
        switch (context) {
            case "mic_request": message = "Requesting microphone..."; break;
            case "finalizing_recording": message = "Finalizing audio..."; break;
            case "uploading_prepare": message = "Preparing upload..."; break;
            case "uploading_to_backend": message = "Sending audio to backend..."; break; // Updated for backend
            case "transcribing_chunk": message = "Transcribing..."; break; 
            case "finalizing_transcription": message = "Finalizing transcript..."; break;
            default: message = "Processing..."; break;
        }
        loadingMessage.textContent = message;
        loadingOverlay.classList.add('visible');
    }

    // Hide loading overlay
    function hideLoading() { 
        loadingOverlay.classList.remove('visible');
    }

    // Apply theme (light/dark) based on localStorage or system preference
    function applyTheme(theme) { 
        if (theme === 'dark') {
            document.body.classList.add('dark-theme');
            themeToggleCheckbox.checked = true;
        } else {
            document.body.classList.remove('dark-theme');
            themeToggleCheckbox.checked = false;
        }
    }

    // Initial theme application
    const savedTheme = localStorage.getItem('theme');
    if (savedTheme) applyTheme(savedTheme);
    else if (window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches) applyTheme('dark');
    else applyTheme('light'); 

    // Theme toggle listener
    themeToggleCheckbox.addEventListener('change', function() {
        const theme = this.checked ? 'dark' : 'light';
        applyTheme(theme);
        localStorage.setItem('theme', theme);
    });

    // Update UI element states based on recording state
    function updateUIForRecordingState() { 
        startRecordBtn.disabled = recordingState !== 'idle';
        pauseRecordBtn.disabled = recordingState !== 'recording';
        resumeRecordBtn.disabled = recordingState !== 'paused';
        stopRecordBtn.disabled = recordingState === 'idle' || recordingState === 'requesting';
        
        uploadAudioBtn.disabled = recordingState !== 'idle';
        sttServiceSelect.disabled = recordingState !== 'idle';
        topicMedicalCheckbox.disabled = recordingState !== 'idle';
        topicInsuranceCheckbox.disabled = recordingState !== 'idle';
        topicGeneralCheckbox.disabled = recordingState !== 'idle';

        [startRecordBtn, pauseRecordBtn, resumeRecordBtn, stopRecordBtn, uploadAudioBtn].forEach(btn => {
            btn.classList.toggle('disabled', btn.disabled);
        });
    }

    // Update status message displayed to the user
    function updateStatus(message, type = "info") { 
        statusDisplayText.textContent = message;
        statusDisplayText.className = 'status-display-text'; // Reset classes
        if (type === "error") statusDisplayText.classList.add('error');
        if (type === "success") statusDisplayText.classList.add('success');
        
        if (type === "error") console.error(`UI Status (Error): ${message}`);
        else console.log(`UI Status: ${message} (Type: ${type})`);
    }

    // Clear all transcription output fields
    function clearOutputFields() { 
        transcriptOutputConvo.value = "";
        transcriptOutputMultispeaker.value = "";
        detectedTopicsList.innerHTML = '<li>No topics detected yet.</li>';
        detectedTopicsList.classList.add('empty');
        // Clear polished note field
        const polishedPlaceholder = polishedNoteOutput.getAttribute('placeholder') || '';
        polishedNoteOutput.innerHTML = polishedPlaceholder;
        polishedNoteOutput.classList.add('placeholder-active');
     }
    
    // Reset UI and internal state to idle
    function resetToIdle(message = "Idle. Ready to record or upload.", type = "info") { 
        recordingState = 'idle';
        updateUIForRecordingState();
        updateStatus(message, type);

        fileNameDisplay.textContent = "No file selected.";
        if(audioFileUpload.value) audioFileUpload.value = ''; // Clear file input
        allRecordedBlobs = []; 
        activeSpeechSegments = []; 
        vadIsSpeaking = false; 
        vadSpeechStartTime = 0;

        stopWaveformVisualization(); 
        stopVAD(); 
        waveformCanvas.style.display = 'none';

        if (currentStream) {
            currentStream.getTracks().forEach(track => track.stop());
            currentStream = null;
        }
        mediaRecorder = null;
        hideLoading();

        // Reset button texts and animations
        startRecordBtn.textContent = "Start Recording";
        startRecordBtn.classList.remove('animating');
        pauseRecordBtn.textContent = "Pause";
        resumeRecordBtn.textContent = "Resume";
        stopRecordBtn.textContent = "Stop & Transcribe";
        stopRecordBtn.classList.remove('animating');
        uploadAudioBtn.textContent = "Upload Audio File";
        uploadAudioBtn.classList.remove('animating');

        updateUIForRecordingState(); // Re-evaluate button states
     }

    // Start drawing audio waveform on canvas
    function startWaveformVisualization(stream) { 
        if (!audioContext) audioContext = new (window.AudioContext || window.webkitAudioContext)();
        if (audioContext.state === 'suspended') audioContext.resume();
        
        mediaStreamSourceForWaveform = audioContext.createMediaStreamSource(stream);
        analyserForWaveform = audioContext.createAnalyser();
        analyserForWaveform.fftSize = 2048; 
        const bufferLength = analyserForWaveform.frequencyBinCount;
        dataArrayForWaveform = new Uint8Array(bufferLength);
        
        mediaStreamSourceForWaveform.connect(analyserForWaveform);
        waveformCanvas.style.display = 'block';
        drawWaveform();
    }

    // Continuously draw waveform
    function drawWaveform() { 
        if (!analyserForWaveform || !currentStream || !currentStream.active || recordingState === 'idle' || recordingState === 'stopped_for_processing') { 
            stopWaveformVisualization(); 
            return;
        }
        animationFrameId = requestAnimationFrame(drawWaveform); 
        analyserForWaveform.getByteTimeDomainData(dataArrayForWaveform); 

        waveformCtx.fillStyle = getComputedStyle(document.documentElement).getPropertyValue('--output-bg').trim();
        waveformCtx.fillRect(0, 0, waveformCanvas.width, waveformCanvas.height);
        waveformCtx.lineWidth = 2;
        waveformCtx.strokeStyle = getComputedStyle(document.documentElement).getPropertyValue('--accent-primary').trim();
        waveformCtx.beginPath();
        const sliceWidth = waveformCanvas.width * 1.0 / dataArrayForWaveform.length;
        let x = 0;
        for (let i = 0; i < dataArrayForWaveform.length; i++) { 
            const v = dataArrayForWaveform[i] / 128.0; 
            const y = v * waveformCanvas.height / 2;
            if (i === 0) waveformCtx.moveTo(x, y);
            else waveformCtx.lineTo(x, y);
            x += sliceWidth;
        }
        waveformCtx.lineTo(waveformCanvas.width, waveformCanvas.height / 2);
        waveformCtx.stroke();
    }

    // Stop waveform visualization
    function stopWaveformVisualization() { 
        if (animationFrameId) cancelAnimationFrame(animationFrameId);
        animationFrameId = null;
        if (waveformCtx) waveformCtx.clearRect(0, 0, waveformCanvas.width, waveformCanvas.height);
        if (mediaStreamSourceForWaveform) { try { mediaStreamSourceForWaveform.disconnect(); } catch(e) { console.warn("Error disconnecting mediaStreamSourceForWaveform:", e); } }
        if (analyserForWaveform) { try { analyserForWaveform.disconnect(); } catch(e) { console.warn("Error disconnecting analyserForWaveform:", e); } }
     }

    // Start Voice Activity Detection
    function startVAD(stream) { 
        if (!audioContext) audioContext = new (window.AudioContext || window.webkitAudioContext)();
        if (audioContext.state === 'suspended') audioContext.resume();

        mediaStreamSourceForVAD = audioContext.createMediaStreamSource(stream);
        vadAnalyserNode = audioContext.createAnalyser();
        vadAnalyserNode.fftSize = 512; 
        vadAnalyserNode.smoothingTimeConstant = 0.5; 

        // Check for createScriptProcessor availability and warn about deprecation
        if (typeof audioContext.createScriptProcessor !== 'function') {
            console.warn("audioContext.createScriptProcessor is not available or is deprecated. VAD will not run. Consider AudioWorkletNode.");
            updateStatus("VAD (advanced) not fully available in this browser or is deprecated.", "info");
            return; 
        }

        const bufferSize = vadAnalyserNode.fftSize;
        vadProcessorNode = audioContext.createScriptProcessor(bufferSize, 1, 1);
        const vadDataArray = new Uint8Array(vadAnalyserNode.frequencyBinCount);

        vadProcessorNode.onaudioprocess = function(audioProcessingEvent) {
            if (recordingState !== 'recording' || !vadProcessorNode) return; 

            vadAnalyserNode.getByteFrequencyData(vadDataArray); // Get frequency domain data

            // Calculate average energy
            let sum = 0;
            for (let i = 0; i < vadDataArray.length; i++) {
                sum += vadDataArray[i];
            }
            const averageEnergy = sum / vadDataArray.length / 255; // Normalize to 0-1

            const currentTime = audioContext.currentTime; 

            if (averageEnergy > VAD_SILENCE_THRESHOLD) { 
                if (!vadIsSpeaking) { 
                    vadIsSpeaking = true;
                    vadSpeechStartTime = currentTime;
                }
            } else { 
                if (vadIsSpeaking) { 
                    // Speech ended, if it was long enough, record the segment
                    if ((currentTime - vadSpeechStartTime) * 1000 >= VAD_MIN_SPEECH_DURATION_MS) {
                        activeSpeechSegments.push({ start: vadSpeechStartTime, end: currentTime });
                        console.log(`VAD: Detected speech segment [${vadSpeechStartTime.toFixed(2)}s - ${currentTime.toFixed(2)}s]`);
                    }
                    vadIsSpeaking = false;
                    vadSpeechStartTime = 0; 
                }
            }
        };

        mediaStreamSourceForVAD.connect(vadAnalyserNode);
        vadAnalyserNode.connect(vadProcessorNode);
        vadProcessorNode.connect(audioContext.destination); // Connect to destination to keep it alive
        console.log("VAD System Initialized & Started");
    }

    // Stop Voice Activity Detection
    function stopVAD() { 
        // Capture any ongoing speech segment when VAD stops
        if (vadIsSpeaking && vadSpeechStartTime > 0 && audioContext && audioContext.currentTime) { 
             const currentTime = audioContext.currentTime;
             if(currentTime > vadSpeechStartTime && (currentTime - vadSpeechStartTime) * 1000 >= VAD_MIN_SPEECH_DURATION_MS) {
                activeSpeechSegments.push({ start: vadSpeechStartTime, end: currentTime });
                console.log(`VAD: Final speech segment [${vadSpeechStartTime.toFixed(2)}s - ${currentTime.toFixed(2)}s] on stop.`);
             }
        }
        vadIsSpeaking = false;
        vadSpeechStartTime = 0;

        if (mediaStreamSourceForVAD) { try { mediaStreamSourceForVAD.disconnect(); } catch(e){ console.warn("Error disconnecting mediaStreamSourceForVAD on stop:", e); } }
        if (vadAnalyserNode) { try { vadAnalyserNode.disconnect(); } catch(e){ console.warn("Error disconnecting vadAnalyserNode on stop:", e); } }
        if (vadProcessorNode) { 
            try { vadProcessorNode.disconnect(); } catch(e){ console.warn("Error disconnecting vadProcessorNode on stop:", e); } 
            vadProcessorNode.onaudioprocess = null; // Clear event handler
        } 
        console.log("VAD System Stopped. All detected speech segments:", activeSpeechSegments);
     }
    
    // Event listener for Start Recording button
    startRecordBtn.addEventListener('click', async () => { 
        // Frontend API key validation removed, as backend handles it securely.
        // The frontend only ensures *a* service is selected.

        if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) { 
            updateStatus("Microphone access not supported by your browser.", "error"); return; 
        }
        
        clearOutputFields(); 
        activeSpeechSegments = []; // Reset VAD segments
        updateStatus("Requesting microphone access...", "info"); 
        showLoading("mic_request");
        recordingState = 'requesting'; 
        updateUIForRecordingState();
        startRecordBtn.textContent = "Requesting mic...";

        try {
            currentStream = await navigator.mediaDevices.getUserMedia({ audio: true, video: false });
            
            hideLoading(); 
            recordingState = 'recording'; 
            updateStatus("Recording...", "info"); 
            // showLoading("recording_start"); // Custom message, doesn't use overlay
            updateUIForRecordingState();
            startRecordBtn.textContent = "Recording..."; 
            startRecordBtn.classList.add('animating'); // Add pulsing animation

            startWaveformVisualization(currentStream); // Start visualizer only during recording
            startVAD(currentStream); // Start VAD when recording starts

            allRecordedBlobs = []; 
            let options = { mimeType: 'audio/webm;codecs=opus' }; 
            if (!MediaRecorder.isTypeSupported(options.mimeType)) { 
                options.mimeType = 'audio/webm';
                if (!MediaRecorder.isTypeSupported(options.mimeType)) options = {}; // Fallback to browser default
            }

            mediaRecorder = new MediaRecorder(currentStream, options);
            mediaRecorder.ondataavailable = event => {
                if (event.data.size > 0) allRecordedBlobs.push(event.data);
            };

            mediaRecorder.onstop = async () => {
                stopVAD(); // Stop VAD and finalize segments
                startRecordBtn.classList.remove('animating');
                stopRecordBtn.classList.remove('animating');

                if (recordingState !== 'stopped_for_processing') { 
                    console.warn("MediaRecorder.onstop called unexpectedly. Assuming stop for processing.");
                    recordingState = 'stopped_for_processing'; 
                    updateStatus("Recording stopped. Processing audio...", "info");
                    showLoading("finalizing_recording"); 
                }
                
                stopWaveformVisualization(); // Stop visualizer after recording ends
                waveformCanvas.style.display = 'none';

                if (allRecordedBlobs.length > 0) {
                    // Combine all recorded chunks into a single Blob
                    const completeOriginalBlob = new Blob(allRecordedBlobs, { type: allRecordedBlobs[0].type || 'audio/webm' });
                    allRecordedBlobs = []; // Clear blobs after combining

                    const timestamp = new Date().toISOString();
                    const recordingName = `recording-${timestamp.replace(/[:.]/g, '-')}.webm`;
                    
                    await saveAudioToDB(completeOriginalBlob, recordingName); // Save to IndexedDB and trigger list refresh
                    
                    await processAndTranscribeAudio(completeOriginalBlob, recordingName);
                } else { 
                    resetToIdle("No audio data recorded.", "info"); 
                }
                
                // Stop all tracks on the stream to release microphone
                if (currentStream) { 
                   currentStream.getTracks().forEach(track => track.stop());
                   currentStream = null;
                }
                updateUIForRecordingState();
            };
            mediaRecorder.onerror = (event) => { 
                console.error("MediaRecorder error:", event.error);
                resetToIdle(`Recorder error: ${event.error.name}. Check console.`, "error"); 
                stopVAD(); 
                startRecordBtn.classList.remove('animating'); 
                hideLoading();
            };
            
            const MEDIA_RECORDER_TIMESLICE_MS = 3000; // Define locally if not global
            mediaRecorder.start(MEDIA_RECORDER_TIMESLICE_MS); // Start recording, collecting data every X ms
        } catch (err) { 
            console.error("Microphone access error:", err);
            let msg = `Mic access error: ${err.name} - ${err.message}.`;
            if (err.name === "NotAllowedError") msg = "Mic permission denied. Please allow access.";
            if (err.name === "NotFoundError") msg = "No microphone found.";
            resetToIdle(msg, "error"); 
            stopVAD(); 
            startRecordBtn.classList.remove('animating'); 
            hideLoading(); 
        }
    });

    // Event listener for Pause Recording button
    pauseRecordBtn.addEventListener('click', () => { 
        if (mediaRecorder && mediaRecorder.state === "recording") { 
            mediaRecorder.pause(); 
            recordingState = 'paused'; 
            updateStatus("Recording paused.", "info"); 
            updateUIForRecordingState(); 
            startRecordBtn.textContent = "Paused"; 
            startRecordBtn.classList.remove('animating'); // Stop pulsing
            // Disconnect VAD processor to pause processing
            if (vadProcessorNode && audioContext) { 
                 try { vadProcessorNode.disconnect(); } catch(e){ console.warn("Error disconnecting VAD processor on pause:", e); }
            }
            console.log("VAD processing paused");
            // Stop waveform visualization temporarily
            stopWaveformVisualization(); 
            waveformCanvas.style.display = 'none';
        }
    });

    // Event listener for Resume Recording button
    resumeRecordBtn.addEventListener('click', () => { 
        if (mediaRecorder && mediaRecorder.state === "paused") { 
            mediaRecorder.resume(); 
            recordingState = 'recording'; 
            updateStatus("Recording resumed...", "info"); 
            updateUIForRecordingState(); 
            startRecordBtn.textContent = "Recording..."; 
            startRecordBtn.classList.add('animating'); // Resume pulsing
            // Reconnect VAD processor to resume processing
            if (vadProcessorNode && vadAnalyserNode && audioContext && audioContext.destination) { 
                try{
                    vadAnalyserNode.connect(vadProcessorNode); 
                    vadProcessorNode.connect(audioContext.destination); 
                    console.log("VAD processing resumed");
                } catch(e) {
                    console.warn("Error reconnecting VAD on resume:", e);
                }
            }
            // Resume waveform visualization
            if (currentStream) {
                startWaveformVisualization(currentStream);
            }
        }
     });

    // Event listener for Stop Recording button
    stopRecordBtn.addEventListener('click', () => { 
        if (mediaRecorder && (mediaRecorder.state === "recording" || mediaRecorder.state === "paused")) {
            recordingState = 'stopped_for_processing'; // Set state to indicate processing will follow
            updateUIForRecordingState(); 
            startRecordBtn.classList.remove('animating'); 
            stopRecordBtn.textContent = "Finalizing..."; 
            stopRecordBtn.classList.add('animating'); // Add pulsing
            showLoading("finalizing_recording"); 
            mediaRecorder.stop(); // This triggers mediaRecorder.onstop
        } else { 
            resetToIdle("Not actively recording or already stopped.", "info"); 
        }
    });

    // Event listener for Upload Audio File button (triggers hidden file input)
    uploadAudioBtn.addEventListener('click', () => { 
        // Frontend API key validation removed, as backend handles it securely.
        
        if (recordingState !== 'idle') { 
            updateStatus("Please stop any current recording process first.", "info"); return; 
         } 
         audioFileUpload.click(); 
    });

    // Event listener for actual file input change (when a file is selected)
    audioFileUpload.addEventListener('change', async (event) => { 
        const file = event.target.files[0];
        if (file) {
            fileNameDisplay.textContent = `Selected: ${file.name}`;
            clearOutputFields();
            updateStatus(`Preparing "${file.name}"...`, "info");
            showLoading("uploading_prepare"); 
            uploadAudioBtn.textContent = "Processing..."; 
            uploadAudioBtn.classList.add('animating'); 
            
            const originalFileName = file.name;

            await saveAudioToDB(file, originalFileName); // Save to IndexedDB and trigger list refresh
            
            await processAndTranscribeAudio(file, originalFileName);
        } else { 
            fileNameDisplay.textContent = "No file selected."; 
            uploadAudioBtn.textContent = "Upload Audio File";
            uploadAudioBtn.classList.remove('animating');
        }
        event.target.value = null; // Clear the file input to allow re-uploading the same file
        updateUIForRecordingState();
    });

    // Function to load and render recorded audio from IndexedDB
    async function loadAndRenderRecordedAudio() {
        if (!db) {
            console.warn("IndexedDB not ready. Cannot load recordings.");
            return;
        }
        recordedAudioList.innerHTML = ''; // Clear existing list

        const transaction = db.transaction([STORE_NAME], 'readonly');
        const store = transaction.objectStore(STORE_NAME);
        const request = store.getAll();

        request.onsuccess = event => {
            let recordings = event.target.result;
            if (recordings.length === 0) {
                recordedAudioList.innerHTML = '<li class="empty-list-message">No recordings yet.</li>';
                return;
            }

            // Sort by timestamp in descending order (newest first)
            recordings.sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp));

            recordings.forEach(record => {
                const listItem = document.createElement('li');
                const audioName = record.name;
                const audioTimestamp = new Date(record.timestamp).toLocaleString();
                const audioUrl = URL.createObjectURL(record.blob);

                listItem.innerHTML = `
                    <p><strong>${audioName}</strong></p>
                    <p class="audio-metadata">Recorded: ${audioTimestamp} | Size: ${(record.blob.size / (1024 * 1024)).toFixed(2)} MB</p>
                    <audio controls src="${audioUrl}"></audio>
                `;
                recordedAudioList.appendChild(listItem);

                // Revoke URL when audio is no longer needed (e.g., on page unload or list refresh)
                const audioElement = listItem.querySelector('audio');
                audioElement.onloadedmetadata = () => URL.revokeObjectURL(audioUrl); 
                audioElement.onerror = () => URL.revokeObjectURL(audioUrl);
            });
        };

        request.onerror = event => {
            console.error("Error loading recordings from IndexedDB:", event.target.error);
            recordedAudioList.innerHTML = '<li class="empty-list-message" style="color: var(--error-color);">Error loading recordings.</li>';
        };
    }


    // Display client-side keyword-matched topics (for OpenAI or Gemini)
    function displayClientSideTopics(text) { 
        const detected = new Set();
        const lowerText = text.toLowerCase();

        if (topicMedicalCheckbox.checked) {
            for (const keyword of TOPIC_KEYWORDS_LOCAL.medical) {
                if (lowerText.includes(keyword.toLowerCase())) {
                    detected.add("Medical (Singapore) - Keyword Match");
                    break; // Add only once per category
                }
            }
        }
        if (topicInsuranceCheckbox.checked) { 
             for (const keyword of TOPIC_KEYWORDS_LOCAL.insurance) {
                if (lowerText.includes(keyword.toLowerCase())) {
                    detected.add("Insurance (Singapore) - Keyword Match");
                    break;
                }
            }
        }
        
        // If General is checked, add General only if no specific topics were found
        if (topicGeneralCheckbox.checked && detected.size === 0) { 
            detected.add("General - Keyword Match");
        }

        detectedTopicsList.innerHTML = ''; // Clear previous list
        if (detected.size > 0) {
            detectedTopicsList.classList.remove('empty');
            detected.forEach(topic => {
                const listItem = document.createElement('li');
                listItem.textContent = topic;
                detectedTopicsList.appendChild(listItem);
            });
        } else {
            detectedTopicsList.classList.add('empty');
            detectedTopicsList.innerHTML = '<li>No focused topics detected by client-side keywords.</li>';
        }
    }

    // Display topics received from backend (e.g., Deepgram native topics)
    function displayBackendTopics(backendTopics) {
        detectedTopicsList.innerHTML = '';
        if (backendTopics && Array.isArray(backendTopics) && backendTopics.length > 0) {
            detectedTopicsList.classList.remove('empty');
            backendTopics.forEach(topicObj => {
                const listItem = document.createElement('li');
                if (typeof topicObj === 'string') {
                   listItem.textContent = topicObj; // Directly use string
                } else if (topicObj.topic) {
                   listItem.textContent = `${topicObj.topic} (Confidence: ${topicObj.confidence ? topicObj.confidence.toFixed(2) : 'N/A'})`;
                }
                detectedTopicsList.appendChild(listItem);
            });
        } else {
            detectedTopicsList.classList.add('empty');
            detectedTopicsList.innerHTML = '<li>No topics detected by the backend.</li>';
        }
    }
    
    // Main function to process and transcribe audio by sending to backend
    async function processAndTranscribeAudio(inputAudioBlob, originalFileName) {
        if (!loadingOverlay.classList.contains('visible')) {
            showLoading("transcribing_chunk"); 
        }

        const targetButtonForAnimation = recordingState === 'stopped_for_processing' ? stopRecordBtn : uploadAudioBtn;
        targetButtonForAnimation.textContent = "Transcribing...";
        targetButtonForAnimation.classList.add('animating');

        const selectedSttService = sttServiceSelect.value;
        
        // Collect topic focus options from checkboxes
        const topicFocusOptions = {
            medical: topicMedicalCheckbox.checked,
            insurance: topicInsuranceCheckbox.checked,
            general: topicGeneralCheckbox.checked,
        };

        const formData = new FormData();
        formData.append('audio', inputAudioBlob, originalFileName);
        formData.append('sttService', selectedSttService);
        formData.append('topicFocus', JSON.stringify(topicFocusOptions)); // Stringify object for formData

        updateStatus(`Sending audio to backend for ${selectedSttService} transcription...`, "info");
        showLoading("uploading_to_backend");

        try {
            const response = await fetch(`${BACKEND_API_BASE_URL}/api/transcribe`, {
                method: 'POST',
                body: formData,
            });

            if (!response.ok) {
                const errorData = await response.json();
                throw new Error(errorData.error || `Backend error: ${response.status}`);
            }

            const data = await response.json();
            console.log("Backend Response:", data);

            transcriptOutputConvo.value = data.transcription.fullTranscript || "No full transcript provided.";

            // Multispeaker output - now combines timestamped/speaker data
            let multispeakerTextOutput = "";
            if (data.transcription.multispeakerOutput && Array.isArray(data.transcription.multispeakerOutput) && data.transcription.multispeakerOutput.length > 0) {
                // Check if it's actual speaker diarization or just segments (Deepgram vs OpenAI)
                const hasSpeakers = data.transcription.multispeakerOutput.some(seg => typeof seg.speaker !== 'undefined' && seg.speaker !== null && seg.speaker !== 'N/A' && seg.speaker !== '0'); // Speaker 0 can be a valid label from Deepgram
                
                data.transcription.multispeakerOutput.forEach(speakerSegment => {
                    const speakerLabel = (typeof speakerSegment.speaker !== 'undefined' && speakerSegment.speaker !== null && speakerSegment.speaker !== 'N/A') ? `Speaker ${speakerSegment.speaker}: ` : '';
                    multispeakerTextOutput += `[${speakerLabel}${speakerSegment.start.toFixed(2)}s - ${speakerSegment.end.toFixed(2)}s] ${speakerSegment.transcript || speakerSegment.text}\n`;
                });
                
                if (!hasSpeakers && selectedSttService === 'openai_whisper') {
                     multispeakerTextOutput += "\n(Note: OpenAI Whisper provides time segments but not speaker labels.)";
                } else if (selectedSttService === 'google_gemini_audio') {
                    multispeakerTextOutput = "(Google Gemini Audio Description does not provide speaker labels or granular time segments.)";
                }

            } else if (selectedSttService === 'google_gemini_audio') {
                 multispeakerTextOutput = "(Google Gemini Audio Description does not provide speaker labels or granular time segments.)";
            } else if (data.transcription.fullTranscript) {
                // Fallback to full transcript if no structured segments/multispeaker data
                multispeakerTextOutput = data.transcription.fullTranscript + "\n\n(No granular segments or speaker labels provided by this service.)";
            } else {
                 multispeakerTextOutput = "No granular segments or speaker labels provided.";
            }
            transcriptOutputMultispeaker.value = multispeakerTextOutput.trim();

            // Detected topics - prioritize backend-provided topics, else fallback to client-side
            if (data.transcription.detectedTopics && Array.isArray(data.transcription.detectedTopics) && data.transcription.detectedTopics.length > 0 && 
                !(data.transcription.detectedTopics.length === 1 && data.transcription.detectedTopics[0].topic && data.transcription.detectedTopics[0].topic.includes("Client-side keyword matching"))) {
                // If backend provided actual topics (e.g., Deepgram's native topics), display them
                displayBackendTopics(data.transcription.detectedTopics); 
            } else {
                // Otherwise, perform client-side keyword matching on the full transcript
                displayClientSideTopics(data.transcription.fullTranscript); 
            }

            // Polished Note
            if (data.transcription.polishedNote) {
                polishedNoteOutput.innerHTML = simpleMarkdownToHtml(data.transcription.polishedNote);
                polishedNoteOutput.classList.remove('placeholder-active');
            } else {
                const placeholder = polishedNoteOutput.getAttribute('placeholder') || '';
                polishedNoteOutput.innerHTML = placeholder;
                polishedNoteOutput.classList.add('placeholder-active');
            }

            resetToIdle(`Transcription of "${originalFileName}" complete with ${selectedSttService}!`, "success");

        } catch (error) {
            console.error('Frontend encountered backend error:', error);
            resetToIdle(`Transcription failed: ${error.message}`, "error");
        } finally {
            targetButtonForAnimation.classList.remove('animating');
        }
    }
    
    // Initialize UI state on load
    resetToIdle(); 
});
EOF

echo "Creating backend files..."

# backend/package.json
cat << 'EOF' > backend/package.json
{
  "name": "transcription-backend",
  "version": "1.0.0",
  "description": "Backend for Finla.ai transcription app",
  "main": "src/server.js",
  "scripts": {
    "start": "node src/server.js",
    "dev": "nodemon src/server.js"
  },
  "keywords": [],
  "author": "",
  "license": "ISC",
  "dependencies": {
    "@google/generative-ai": "^0.14.1",
    "cors": "^2.8.5",
    "dotenv": "^16.4.5",
    "express": "^4.19.2",
    "multer": "^1.4.5-lts.1",
    "node-fetch": "^3.3.2",
    "pg": "^8.12.0",
    "fluent-ffmpeg": "^2.1.3",
    "@ffmpeg-installer/ffmpeg": "^1.1.0"
  },
  "devDependencies": {
    "nodemon": "^3.1.4"
  }
}
EOF

# backend/.env.example
cat << 'EOF' > backend/.env.example
PORT=3000

DB_HOST=postgres_db
DB_PORT=5432
DB_USER=user
DB_PASSWORD=password
DB_NAME=transcription_db

OPENAI_API_KEY="sk-YOUR_OPENAI_API_KEY_HERE"
GEMINI_API_KEY="AIzaSyYOUR_GEMINI_API_KEY_HERE"
DEEPGRAM_API_KEY="Token YOUR_DEEPGRAM_API_KEY_HERE" # Uncomment and set if you plan to use Deepgram

# For AWS S3 integration (optional, if you want to store audio files there)
# AWS_ACCESS_KEY_ID=YOUR_AWS_ACCESS_KEY_ID
# AWS_SECRET_ACCESS_KEY=YOUR_AWS_SECRET_ACCESS_KEY
# AWS_REGION=your-aws-region
# AWS_S3_BUCKET_NAME=your-s3-bucket-name
EOF

# backend/src/config.js
cat << 'EOF' > backend/src/config.js
// backend/src/config.js
require('dotenv').config();

const config = {
    port: process.env.PORT || 3000,
    db: {
        host: process.env.DB_HOST || 'localhost',
        port: process.env.DB_PORT || 5432,
        user: process.env.DB_USER || 'user',
        password: process.env.DB_PASSWORD || 'password',
        database: process.env.DB_NAME || 'transcription_db',
    },
    openaiApiKey: process.env.OPENAI_API_KEY,
    geminiApiKey: process.env.GEMINI_API_KEY,
    deepgramApiKey: process.env.DEEPGRAM_API_KEY, 
    
    // AWS S3 (optional)
    aws: {
        accessKeyId: process.env.AWS_ACCESS_KEY_ID,
        secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
        region: process.env.AWS_REGION || 'us-east-1',
        s3BucketName: process.env.AWS_S3_BUCKET_NAME,
    }
};

// Basic validation for API keys
if (!config.openaiApiKey || config.openaiApiKey.includes("YOUR_OPENAI_API_KEY_HERE")) {
    console.warn("WARNING: OpenAI API Key is not set or is still the placeholder. Transcription may fail for OpenAI.");
}
if (!config.geminiApiKey || config.geminiApiKey.includes("YOUR_GEMINI_API_KEY_HERE")) {
    console.warn("WARNING: Gemini API Key is not set or is still the placeholder. Transcription may fail for Gemini.");
}
if (!config.deepgramApiKey || config.deepgramApiKey.includes("YOUR_DEEPGRAM_API_KEY_HERE")) {
    console.warn("WARNING: Deepgram API Key is not set or is still the placeholder. Deepgram transcription may fail.");
}


module.exports = config;
EOF

# backend/src/db.js
cat << 'EOF' > backend/src/db.js
// backend/src/db.js
const { Pool } = require('pg');
const config = require('./config');

const pool = new Pool({
    host: config.db.host,
    port: config.db.port,
    user: config.db.user,
    password: config.db.password,
    database: config.db.database,
});

pool.on('error', (err, client) => {
    console.error('Unexpected error on idle client', err);
    process.exit(-1); // Exit process if DB connection is lost
});

async function connectDb() {
    try {
        const client = await pool.connect();
        console.log('Connected to PostgreSQL database');
        client.release();
    } catch (err) {
        console.error('Failed to connect to PostgreSQL:', err.message);
        console.error('Ensure PostgreSQL container is running and accessible.');
        // Optionally, exit the process or attempt reconnection
        // process.exit(1); 
    }
}

async function createTables() {
    const client = await pool.connect();
    try {
        await client.query(`
            CREATE TABLE IF NOT EXISTS transcriptions (
                id SERIAL PRIMARY KEY,
                audio_filename VARCHAR(255) NOT NULL,
                stt_service VARCHAR(50) NOT NULL,
                full_transcript TEXT,
                timestamped_segments JSONB,
                multispeaker_output JSONB,
                detected_topics JSONB,
                polished_note TEXT, -- New column for Gemini polished output
                created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
            );
        `);
        console.log('Database tables ensured.');
    } catch (err) {
        console.error('Error creating tables:', err.message);
    } finally {
        client.release();
    }
}

module.exports = {
    query: (text, params) => pool.query(text, params),
    connectDb,
    createTables
};
EOF

# backend/src/models/transcription.js
cat << 'EOF' > backend/src/models/transcription.js
// backend/src/models/transcription.js
const db = require('../db');

async function saveTranscription(data) {
    const {
        audioFilename,
        sttService,
        fullTranscript,
        timestampedSegments,
        multispeakerOutput,
        detectedTopics,
        polishedNote // Include polishedNote
    } = data;

    const query = `
        INSERT INTO transcriptions (
            audio_filename, 
            stt_service, 
            full_transcript, 
            timestamped_segments, 
            multispeaker_output, 
            detected_topics, 
            polished_note
        ) VALUES ($1, $2, $3, $4, $5, $6, $7)
        RETURNING *;
    `;
    const values = [
        audioFilename,
        sttService,
        fullTranscript,
        timestampedSegments,
        multispeakerOutput,
        detectedTopics,
        polishedNote
    ];

    try {
        const res = await db.query(query, values);
        console.log('Transcription saved to DB:', res.rows[0].id);
        return res.rows[0];
    } catch (err) {
        console.error('Error saving transcription to DB:', err.message);
        throw err;
    }
}

module.exports = {
    saveTranscription
};
EOF

# backend/src/services/openaiService.js
cat << 'EOF' > backend/src/services/openaiService.js
// backend/src/services/openaiService.js
const config = require('../config');
const fetch = require('node-fetch'); // For OpenAI API

async function transcribeWithOpenAI(audioBuffer, originalFileName) {
    if (!config.openaiApiKey) {
        throw new Error("OpenAI API Key is not configured in backend/src/config.js");
    }

    const formData = new fetch.FormData();
    formData.append("file", audioBuffer, originalFileName || "audio.webm"); 
    formData.append("model", "whisper-1"); 
    formData.append("response_format", "verbose_json"); 
    formData.append("timestamp_granularities[]", "segment");

    try {
        const response = await fetch("https://api.openai.com/v1/audio/transcriptions", {
            method: "POST",
            headers: {
                "Authorization": `Bearer ${config.openaiApiKey}`,
            },
            body: formData,
        });

        const responseBody = await response.json();

        if (!response.ok) {
            let errDetails = `OpenAI API Error - Status: ${response.status}.`;
            if (responseBody.error && responseBody.error.message) {
                errDetails = responseBody.error.message;
            }
            throw new Error(errDetails);
        }

        const data = responseBody;
        
        // OpenAI Whisper provides segments, but not direct speaker diarization.
        // Map segments for multispeaker output format.
        const multispeakerOutput = (data.segments || []).map(s => ({
            start: s.start,
            end: s.end,
            text: s.text,
            speaker: null // Explicitly null as OpenAI doesn't provide this
        }));

        return {
            fullTranscript: data.text || "",
            timestampedSegments: null, 
            multispeakerOutput: multispeakerOutput, 
            detectedTopics: null, // Frontend will perform client-side keyword matching
            polishedNote: null 
        };

    } catch (error) {
        console.error("Error transcribing with OpenAI:", error);
        throw error;
    }
}

module.exports = {
    transcribeWithOpenAI
};
EOF

# backend/src/services/deepgramService.js
cat << 'EOF' > backend/src/services/deepgramService.js
// backend/src/services/deepgramService.js
const config = require('../config');
const fetch = require('node-fetch');

async function transcribeWithDeepgram(audioBuffer, audioMimeType, topicFocusOptions) {
    if (!config.deepgramApiKey) {
        throw new Error("Deepgram API Key is not configured in backend/src/config.js");
    }

    const params = new URLSearchParams({
        model: 'nova-3', 
        diarize: 'true',
        smart_format: 'true',
        paragraphs: 'true',
        sentiment: 'false', 
        detect_language: 'true', 
        topics: 'true', 
        custom_topic_mode: 'strict' 
    });

    const customTopics = [];
    if (topicFocusOptions.medical) customTopics.push('medical', 'doctor', 'health', 'medicine', 'patient', 'clinic', 'hospital'); 
    if (topicFocusOptions.insurance) customTopics.push('insurance', 'policy', 'premium', 'coverage', 'claim', 'underwriting', 'beneficiary', 'sum assured');
    if (topicFocusOptions.general) customTopics.push('general', 'conversation', 'everyday');
    
    customTopics.forEach(topic => params.append('custom_topic', topic));

    const deepgramUrl = `https://api.deepgram.com/v1/listen?${params.toString()}`;

    try {
        const response = await fetch(deepgramUrl, {
            method: 'POST',
            headers: {
                'Authorization': config.deepgramApiKey,
                'Content-Type': audioMimeType
            },
            body: audioBuffer
        });

        const responseBodyText = await response.text();

        if (!response.ok) {
            let errDetails = `Deepgram API Error - Status: ${response.status}.`;
            try {
                const errorJson = JSON.parse(responseBodyText);
                if (errorJson.err_msg) errDetails = errorJson.err_msg; 
                else if (errorJson.reason) errDetails = errorJson.reason;
                else if (errorJson.message) errDetails = errorJson.message;
            } catch (e) { /* response was not JSON */ }
            throw new Error(errDetails);
        }

        const data = JSON.parse(responseBodyText);
        
        let fullTranscript = "";
        let multispeakerOutput = [];
        let detectedTopics = [];

        if (data.results && data.results.channels && data.results.channels.length > 0) {
            const channel = data.results.channels[0];
            if (channel.alternatives && channel.alternatives.length > 0) {
                fullTranscript = channel.alternatives[0].transcript || "";

                // Populate multispeaker output using diarized utterances if available
                if (data.results.utterances) { 
                    multispeakerOutput = data.results.utterances.map(u => ({
                        speaker: u.speaker,
                        start: u.start,
                        end: u.end,
                        transcript: u.transcript
                    }));
                } else if (channel.alternatives[0].words) { 
                    // Fallback to timestamped segments if diarization is not available
                    let currentSegment = "";
                    let segmentStartTime = -1;
                    channel.alternatives[0].words.forEach(word => {
                        if (segmentStartTime === -1) segmentStartTime = word.start;
                        currentSegment += word.punctuated_word ? word.punctuated_word + " " : word.word + " ";
                        if (word.punctuated_word && word.punctuated_word.match(/[.?!]/)) { 
                             multispeakerOutput.push({
                                 speaker: null, // No speaker for this fallback
                                 start: segmentStartTime,
                                 end: word.end,
                                 transcript: currentSegment.trim()
                             });
                             currentSegment = "";
                             segmentStartTime = -1;
                        }
                    });
                    if(currentSegment) multispeakerOutput.push({
                         speaker: null,
                         start: segmentStartTime,
                         end: channel.alternatives[0].words.slice(-1)[0].end,
                         transcript: currentSegment.trim()
                    }); 
                }

                // Deepgram's native topics
                if (data.results.summary && data.results.summary.topics) {
                    detectedTopics = data.results.summary.topics;
                } else if (data.results.topics) { 
                    detectedTopics = data.results.topics;
                }
            }
        }
        
        return {
            fullTranscript,
            timestampedSegments: null, 
            multispeakerOutput,
            detectedTopics,
            polishedNote: null 
        };

    } catch (error) {
        console.error('Error transcribing with Deepgram:', error);
        throw error;
    }
}

module.exports = {
    transcribeWithDeepgram
};
EOF

# backend/src/services/geminiService.js
cat << 'EOF' > backend/src/services/geminiService.js
// backend/src/services/geminiService.js
const { GoogleGenerativeAI } = require('@google/generative-ai');
const config = require('../config');

const MODEL_NAME_GEMINI_STT = 'gemini-1.5-flash-latest'; // 'gemini-1.5-flash-latest' for multimodal input
const MODEL_NAME_GEMINI_POLISH = 'gemini-1.5-flash-latest'; // Consistent model for text transformation

const genAI = new GoogleGenerativeAI(config.geminiApiKey);

// Helper function to convert Buffer to a format suitable for Gemini's inlineData
function bufferToBase64(buffer, mimeType) {
    return {
        inlineData: {
            mimeType: mimeType,
            data: buffer.toString('base64')
        }
    };
}

async function transcribeWithGemini(audioBuffer, mimeType) {
    if (!config.geminiApiKey) {
        throw new Error("Gemini API Key is not configured in backend/src/config.js");
    }

    try {
        const audioPart = bufferToBase64(audioBuffer, mimeType);
        const textPart = { text: 'Analyze this audio. Provide a detailed transcription of any speech, including speaker turns if distinguishable. If no speech, describe the audio content. Summarize key discussion points if applicable.' };

        const model = genAI.getGenerativeModel({ model: MODEL_NAME_GEMINI_STT });
        const result = await model.generateContent({
            contents: [{ parts: [textPart, audioPart] }],
            safety_settings: [
                { category: "HARM_CATEGORY_HATE_SPEECH", threshold: "BLOCK_NONE" },
                { category: "HARM_CATEGORY_SEXUALLY_EXPLICIT", threshold: "BLOCK_NONE" },
                { category: "HARM_CATEGORY_HARASSMENT", threshold: "BLOCK_NONE" },
                { category: "HARM_CATEGORY_DANGEROUS_CONTENT", threshold: "BLOCK_NONE" },
            ],
        });

        const response = await result.response;
        const text = response.text(); 

        // Gemini provides a coherent text block, not granular segments or speaker labels in this usage.
        // We'll return null for timestampedSegments, and a single multispeaker entry for the full text.
        return {
            fullTranscript: text.trim(),
            timestampedSegments: null, 
            multispeakerOutput: [{ 
                speaker: 'N/A', 
                start: 0,
                end: 0, 
                transcript: text.trim()
            }], 
            detectedTopics: null 
        };

    } catch (error) {
        console.error('Error transcribing with Gemini:', error);
        throw error;
    }
}

async function polishTextWithGemini(rawTranscription) {
    if (!rawTranscription || rawTranscription.trim() === '') {
        return null;
    }

    try {
        const prompt = `Take this raw transcription/audio description and create a polished, well-formatted summary or note.
                    Remove filler words (um, uh, like), repetitions, and false starts if present.
                    Format any lists or bullet points properly using markdown. Use markdown for headings, lists, and bold text.
                    Ensure the core content and meaning are preserved. If the input is just a description, refine it into a clear, concise note.

                    Raw input:
                    ${rawTranscription}`;
        
        const model = genAI.getGenerativeModel({ model: MODEL_NAME_GEMINI_POLISH }); 
        const result = await model.generateContent(prompt);
        const response = await result.response;
        const polishedText = response.text();

        return polishedText.trim(); 

    } catch (error) {
        console.error('Error polishing text with Gemini:', error);
        throw error;
    }
}

module.exports = {
    transcribeWithGemini,
    polishTextWithGemini
};
EOF

# backend/src/utils/audioUtils.js
cat << 'EOF' > backend/src/utils/audioUtils.js
// backend/src/utils/audioUtils.js
const ffmpeg = require('fluent-ffmpeg');
const fs = require('fs');
const path = require('path');

// Ensure ffmpeg is available (install via Dockerfile)
ffmpeg.setFfmpegPath(require('@ffmpeg-installer/ffmpeg').path);

async function convertAudioToWav(inputBuffer, inputMimeType) {
    const tempInputPath = path.join('/tmp', `input_audio_${Date.now()}.${inputMimeType.split('/')[1].split(';')[0]}`);
    const tempOutputPath = path.join('/tmp', `output_audio_${Date.now()}.wav`);

    // Write the input buffer to a temporary file
    fs.writeFileSync(tempInputPath, inputBuffer);

    return new Promise((resolve, reject) => {
        ffmpeg(tempInputPath)
            .toFormat('wav')
            .on('end', () => {
                const wavBuffer = fs.readFileSync(tempOutputPath);
                fs.unlinkSync(tempInputPath); // Clean up temp input file
                fs.unlinkSync(tempOutputPath); // Clean up temp output file
                resolve(wavBuffer);
            })
            .on('error', (err) => {
                console.error('Error converting audio with FFmpeg:', err);
                fs.unlinkSync(tempInputPath); // Clean up temp input file even on error
                try { fs.unlinkSync(tempOutputPath); } catch(e) {} // Try to clean output, ignore if not created
                reject(new Error(`Audio conversion failed: ${err.message}`));
            })
            .save(tempOutputPath);
    });
}

module.exports = {
    convertAudioToWav
};
EOF

# backend/src/server.js
cat << 'EOF' > backend/src/server.js
// backend/src/server.js
const express = require('express');
const multer = require('multer');
const cors = require('cors');
const path = require('path');

const config = require('./config');
const db = require('./db');
const transcriptionModel = require('./models/transcription');
const openaiService = require('./services/openaiService');
const deepgramService = require('./services/deepgramService');
const geminiService = require('./services/geminiService');
// const audioUtils = require('./utils/audioUtils'); // Uncomment if using ffmpeg for explicit conversion before STT service calls

const app = express();
const upload = multer(); // For handling multipart/form-data, primarily file uploads

// Middleware
app.use(cors({
    origin: '*', // WARNING: For production, specify your frontend's domain: e.g., 'https://yourfrontend.com'
    methods: ['GET', 'POST'],
    allowedHeaders: ['Content-Type', 'Authorization'],
}));
app.use(express.json()); // For parsing application/json

// Ensure DB connection and tables on startup
db.connectDb().then(() => db.createTables()).catch(err => console.error("Database initialization failed:", err));

// Serve static frontend files (for local dev or if Nginx isn't serving them)
app.use(express.static(path.join(__dirname, '../../frontend')));

// API Routes
app.post('/api/transcribe', upload.single('audio'), async (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({ error: 'No audio file provided.' });
        }
        if (!req.body.sttService) {
            return res.status(400).json({ error: 'STT service not specified.' });
        }
        // Topic focus is received as a JSON string
        let topicFocusOptions = {};
        try {
            if (req.body.topicFocus) {
                topicFocusOptions = JSON.parse(req.body.topicFocus);
            }
        } catch (parseError) {
            console.warn("Failed to parse topicFocus JSON:", parseError);
        }


        const audioBuffer = req.file.buffer; // Raw buffer of the audio file
        const audioMimeType = req.file.mimetype;
        const originalFileName = req.file.originalname;
        const sttService = req.body.sttService;
        

        console.log(`Received transcription request for ${originalFileName} using ${sttService}`);
        console.log(`Topic Focus: ${JSON.stringify(topicFocusOptions)}`);

        let transcriptionResult = {
            fullTranscript: '',
            timestampedSegments: null,
            multispeakerOutput: null,
            detectedTopics: null,
            polishedNote: null
        };
        
        if (sttService === 'openai_whisper') {
            transcriptionResult = await openaiService.transcribeWithOpenAI(audioBuffer, originalFileName);
            // Frontend will perform client-side keyword matching for OpenAI based on fullTranscript
            // No specific backend topic detection for OpenAI here.
            transcriptionResult.detectedTopics = [{ topic: "OpenAI: Topics derived from client-side keyword matching." }];
        } else if (sttService === 'deepgram_nova') {
            transcriptionResult = await deepgramService.transcribeWithDeepgram(audioBuffer, audioMimeType, topicFocusOptions);
            // Deepgram natively provides topics, so we pass that back.
        } else if (sttService === 'google_gemini_audio') {
            // Step 1: Transcribe (or rather, "describe with speech") with Gemini
            transcriptionResult = await geminiService.transcribeWithGemini(audioBuffer, audioMimeType);
            
            // Step 2: Polish the raw transcript with Gemini
            // This is applied only for Gemini service where a polished note is expected.
            const polishedText = await geminiService.polishTextWithGemini(transcriptionResult.fullTranscript);
            transcriptionResult.polishedNote = polishedText;
            
            // Gemini STT (as used here) doesn't natively provide granular timestamps, speaker labels.
            transcriptionResult.detectedTopics = [{ topic: "Google Gemini: AI-driven description. Topics derived from client-side keyword matching." }];

        } else {
            return res.status(400).json({ error: 'Unsupported STT service.' });
        }

        // Save transcription to database
        const savedRecord = await transcriptionModel.saveTranscription({
            audioFilename: originalFileName,
            sttService: sttService,
            fullTranscript: transcriptionResult.fullTranscript,
            timestampedSegments: transcriptionResult.timestampedSegments, 
            multispeakerOutput: transcriptionResult.multispeakerOutput,
            detectedTopics: transcriptionResult.detectedTopics,
            polishedNote: transcriptionResult.polishedNote
        });

        res.json({
            message: 'Transcription successful',
            transcription: {
                fullTranscript: transcriptionResult.fullTranscript,
                multispeakerOutput: transcriptionResult.multispeakerOutput,
                detectedTopics: transcriptionResult.detectedTopics,
                polishedNote: transcriptionResult.polishedNote
            },
            dbRecordId: savedRecord.id
        });

    } catch (error) {
        console.error('Transcription error:', error.message);
        res.status(500).json({ error: `Transcription failed: ${error.message}` });
    }
});

// Basic health check
app.get('/api/health', (req, res) => {
    res.status(200).json({ status: 'ok', message: 'Backend is running' });
});

// Start the server
const PORT = config.port;
app.listen(PORT, () => {
    console.log(`Server listening on port ${PORT}`);
    console.log(`Access frontend at http://localhost:${PORT}`);
});
EOF

# backend/Dockerfile
cat << 'EOF' > backend/Dockerfile
# backend/Dockerfile
FROM node:20-alpine

# Install build tools and ffmpeg
# FFmpeg is required by fluent-ffmpeg for audio processing
RUN apk add --no-cache python3 make g++ ffmpeg

WORKDIR /usr/src/app

COPY package*.json ./
RUN npm install

COPY . .

# Ensure /tmp directory exists for temporary audio files if fluent-ffmpeg needs it
RUN mkdir -p /tmp

EXPOSE 3000

CMD ["npm", "start"]
EOF

echo "Creating infrastructure files..."

# infrastructure/docker-compose.yml
cat << 'EOF' > infrastructure/docker-compose.yml
version: '3.8'

services:
  backend:
    build:
      context: ../backend # Build from the backend directory
      dockerfile: Dockerfile
    ports:
      - "3000:3000" # Map host port 3000 to container port 3000
    environment:
      # Pass through environment variables from the host's .env file
      - PORT=${PORT}
      - DB_HOST=postgres_db
      - DB_PORT=${DB_PORT}
      - DB_USER=${DB_USER}
      - DB_PASSWORD=${DB_PASSWORD}
      - DB_NAME=${DB_NAME}
      - OPENAI_API_KEY=${OPENAI_API_KEY}
      - GEMINI_API_KEY=${GEMINI_API_KEY}
      - DEEPGRAM_API_KEY=${DEEPGRAM_API_KEY} # Pass Deepgram API key if set
    volumes:
      - ./tmp:/tmp # Mount a temp directory for audio processing (e.g., ffmpeg)
      - ../backend/src:/usr/src/app/src # Mount source for live reload during dev (optional for production)
    depends_on:
      - postgres_db # Ensure database is up before backend starts
    networks:
      - app-network
    restart: on-failure # Restart if container exits with an error

  postgres_db:
    image: postgres:16-alpine # Using a lightweight PostgreSQL image
    ports:
      - "5432:5432" # Map host port 5432 to container port 5432
    environment:
      - POSTGRES_USER=${DB_USER}
      - POSTGRES_PASSWORD=${DB_PASSWORD}
      - POSTGRES_DB=${DB_NAME}
    volumes:
      - db_data:/var/lib/postgresql/data # Persist database data
    networks:
      - app-network
    restart: always # Always restart the database

volumes:
  db_data: # Define the named volume for persistence

networks:
  app-network:
    driver: bridge
EOF

# infrastructure/aws_deploy_notes.md
cat << 'EOF' > infrastructure/aws_deploy_notes.md
# AWS EC2 Deployment Notes

This document outlines the high-level steps to deploy the transcription application to an AWS EC2 instance.

## Prerequisites:
1.  **AWS Account:** With necessary IAM permissions.
2.  **AWS EC2 Instance:** A Linux-based EC2 instance (e.g., Ubuntu, Amazon Linux) with Docker and Docker Compose installed.
    *   Ensure security group allows inbound traffic on ports:
        *   `80` (HTTP for Nginx/frontend)
        *   `443` (HTTPS for Nginx/frontend - highly recommended for production)
        *   `3000` (Backend API, though usually proxied by Nginx)
        *   `5432` (PostgreSQL, consider restricting access to only EC2 instance or a specific subnet for security)
    *   Consider an instance type with sufficient CPU and RAM for audio processing (e.g., `t3.medium` or larger).
3.  **Domain Name:** Recommended for cleaner access and SSL certificates.
4.  **SSH Key:** For connecting to your EC2 instance.

## Deployment Steps:

1.  **Prepare EC2 Instance:**
    *   SSH into your EC2 instance.
    *   Install Docker: `sudo apt-get update && sudo apt-get install docker.io -y` (for Ubuntu)
    *   Add your user to the docker group: `sudo usermod -aG docker $USER && newgrp docker` (re-login or open new session after this)
    *   Install Docker Compose: `sudo apt-get install docker-compose -y` (or download binary if needed)
    *   **IMPORTANT:** Ensure `ffmpeg` is available on the EC2 host for `fluent-ffmpeg` to work, even if installed in Docker. Though the Dockerfile installs it within the container, some `fluent-ffmpeg` operations might interact with the host's `ffmpeg`. If you specifically use `audioUtils.js` to convert, `ffmpeg` needs to be in the container, which the Dockerfile handles.
        `sudo apt-get install ffmpeg -y` (for Ubuntu)

2.  **Transfer Application Code:**
    *   Use `scp` or `git clone` to get your `transcription-app` directory onto the EC2 instance.
    *   Example using `scp`:
        ```bash
        scp -i /path/to/your-key.pem -r transcription-app ubuntu@YOUR_EC2_PUBLIC_IP:~
        ```

3.  **Configure Environment Variables:**
    *   Navigate to the `transcription-app` directory on the EC2 instance.
    *   Create a `.env` file at the root of `transcription-app` (same level as `docker-compose.yml`).
    *   Populate it with your actual API keys, database credentials. **Never commit these to version control.**
        ```bash
        # transcription-app/.env (for docker-compose)
        PORT=3000
        DB_HOST=postgres_db
        DB_PORT=5432
        DB_USER=your_db_user
        DB_PASSWORD=your_db_password
        DB_NAME=transcription_db
        OPENAI_API_KEY="sk-YOUR_OPENAI_KEY_HERE"
        GEMINI_API_KEY="AIzaSyYOUR_GEMINI_KEY_HERE"
        DEEPGRAM_API_KEY="Token YOUR_DEEPGRAM_API_KEY_HERE" # Only if using Deepgram
        ```

4.  **Build and Run Docker Containers:**
    *   Navigate to the `transcription-app/infrastructure` directory.
    *   Build the Docker images: `docker-compose build`
    *   Start the services: `docker-compose up -d` (`-d` for detached mode)
    *   Verify containers are running: `docker-compose ps`

5.  **Database Migrations (First Run):**
    *   The `createTables()` function in `backend/src/db.js` will attempt to create the `transcriptions` table on backend startup. This is a simple migration strategy.

6.  **Set up Nginx (Reverse Proxy & Static File Serving):**
    *   Install Nginx: `sudo apt-get install nginx -y`
    *   Configure Nginx to:
        *   Serve your `frontend` static files (from `transcription-app/frontend`).
        *   Proxy API requests from `/api/` to your `backend` Docker container (port 3000).
        *   Handle SSL/TLS (Certbot recommended).
    *   Example Nginx config (`/etc/nginx/sites-available/default` or a new file in `sites-available` then link to `sites-enabled`):

    ```nginx
    # infrastructure/Nginx.conf.example (copy to EC2 and adjust)
    server {
        listen 80;
        listen [::]:80;
        server_name YOUR_DOMAIN_OR_EC2_IP;

        # Redirect all HTTP to HTTPS for production
        # return 301 https://$host$request_uri;

        location / {
            # Serve frontend static files
            root /path/to/your/transcription-app/frontend; # Adjust this path (e.g., /home/ubuntu/transcription-app/frontend)
            try_files $uri $uri/ /index.html;
        }

        location /api/ {
            # Proxy API requests to the backend container
            # Use the service name defined in docker-compose for inter-container communication
            proxy_pass http://backend:3000; 
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_read_timeout 300s; # Adjust if large audio uploads take long
            proxy_send_timeout 300s;
        }
    }

    # Optional: HTTPS configuration (strongly recommended for production)
    # server {
    #     listen 443 ssl;
    #     listen [::]:443 ssl;
    #     server_name YOUR_DOMAIN;

    #     ssl_certificate /etc/letsencrypt/live/YOUR_DOMAIN/fullchain.pem; # Managed by Certbot
    #     ssl_certificate_key /etc/letsencrypt/live/YOUR_DOMAIN/privkey.pem; # Managed by Certbot
    #     include /etc/letsencrypt/options-ssl-nginx.conf;
    #     ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

    #     location / {
    #         root /path/to/your/transcription-app/frontend; # Adjust this path
    #         try_files $uri $uri/ /index.html;
    #     }

    #     location /api/ {
    #         proxy_pass http://backend:3000;
    #         proxy_set_header Host $host;
    #         proxy_set_header X-Real-IP $remote_addr;
    #         proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    #         proxy_set_header X-Forwarded-Proto $scheme;
    #         proxy_read_timeout 300s;
    #         proxy_send_timeout 300s;
    #     }
    # }
    ```
    *   Test Nginx config: `sudo nginx -t`
    *   Restart Nginx: `sudo systemctl restart nginx`
    *   (Optional but recommended) Install Certbot for SSL: `sudo apt-get install certbot python3-certbot-nginx -y` then `sudo certbot --nginx -d YOUR_DOMAIN`

7.  **Monitor Logs:**
    *   Backend logs: `docker-compose logs -f backend`
    *   Nginx logs: `tail -f /var/log/nginx/access.log /var/log/nginx/error.log`
EOF

# Project-level .env.example
cat << 'EOF' > .env.example
# Project-level Environment Variables for Docker Compose
# Copy this file to .env and fill in your actual values.

PORT=3000

# PostgreSQL Database Configuration
DB_HOST=postgres_db
DB_PORT=5432
DB_USER=user
DB_PASSWORD=password
DB_NAME=transcription_db

# API Keys (Replace with your actual keys)
OPENAI_API_KEY="sk-YOUR_OPENAI_API_KEY_HERE"
GEMINI_API_KEY="AIzaSyYOUR_GEMINI_API_KEY_HERE"
# If you decide to use Deepgram, uncomment and set the key:
# DEEPGRAM_API_KEY="Token YOUR_DEEPGRAM_API_KEY_HERE"

# AWS S3 Configuration (Optional - for storing audio files in S3)
# Uncomment these and fill in your AWS credentials if you want to enable S3 storage.
# You will also need to add S3 upload logic to the backend/src/server.js
# AWS_ACCESS_KEY_ID=YOUR_AWS_ACCESS_KEY_ID
# AWS_SECRET_ACCESS_KEY=YOUR_AWS_SECRET_ACCESS_KEY
# AWS_REGION=your-aws-region # e.g., us-east-1
# AWS_S3_BUCKET_NAME=your-s3-bucket-name
EOF

# Root README.md
cat << 'EOF' > README.md
# Finla.ai Transcription Application

This is a full-stack transcription application with a client-side UI and a Node.js/Express backend that integrates with OpenAI Whisper and Google Gemini for Speech-to-Text (STT) services, storing transcription results in a Dockerized PostgreSQL database.

## Architecture

*   **Frontend:** Pure HTML, CSS, and JavaScript (served statically). Handles audio recording/upload, microphone visualizer, and displaying transcription results, including a polished note generated by Gemini. All sensitive operations are offloaded to the backend.
*   **Backend:** A Node.js application built with Express.js, running in a Docker container. It exposes API endpoints for transcription, securely manages API keys (via environment variables), interacts with STT services (OpenAI, Gemini for STT and polishing), and persists data to PostgreSQL. It also leverages `ffmpeg` for potential audio format conversions.
*   **Database:** PostgreSQL, running in a Docker container, with persistent data storage.
*   **Deployment:** Designed for deployment on an AWS EC2 instance using Docker and Docker Compose. Nginx is recommended as a reverse proxy for serving the frontend and directing API traffic.

## Project Structure

```
transcription-app/
├── backend/
│   ├── src/                  # Node.js Express application source code
│   │   ├── server.js             # Main Express application setup and routes
│   │   ├── config.js             # Configuration loading (env vars)
│   │   ├── db.js                 # PostgreSQL client setup and connection pool
│   │   ├── models/               # Database interaction (e.g., SQL queries)
│   │   │   └── transcription.js  # Functions for interacting with the 'transcriptions' table
│   │   ├── services/
│   │   │   ├── openaiService.js  # Logic for interacting with OpenAI API
│   │   │   ├── deepgramService.js# Logic for interacting with Deepgram API (if enabled)
│   │   │   └── geminiService.js  # Logic for interacting with Google Gemini API
│   │   └── utils/
│   │       └── audioUtils.js     # Helper for audio processing (e.g., format conversion with ffmpeg)
│   ├── Dockerfile            # Dockerfile for building the backend image
│   ├── package.json          # Node.js dependencies
│   ├── package-lock.json     # Generated by npm install
│   └── .env.example          # Example environment variables for the backend container
├── frontend/
│   ├── index.html            # Main UI HTML with new polished note field
│   ├── css/                  # Application CSS
│   └── js/                   # Application JavaScript (with visualizer and backend calls)
├── infrastructure/
│   ├── docker-compose.yml    # Docker Compose setup for local development
│   ├── aws_deploy_notes.md   # Notes for AWS EC2 deployment
│   └── Nginx.conf.example    # Example Nginx configuration
├── .env.example              # Project-level environment variables for Docker Compose
└── README.md                 # This README file
```

## Local Development Setup

### Prerequisites

*   **Docker Desktop** (or Docker Engine and Docker Compose if on Linux)
*   Basic understanding of Node.js and npm (though Docker handles most installs).

### Steps

1.  **Run the setup script:**
    Save the provided bash script (e.g., `setup_transcription_app.sh`) and execute it:
    ```bash
    chmod +x setup_transcription_app.sh
    ./setup_transcription_app.sh
    ```
    This script will create the `transcription-app` directory and all its contents.

2.  **Configure Environment Variables:**
    *   Navigate into the `transcription-app` directory created by the script:
        ```bash
        cd transcription-app
        ```
    *   Copy the example environment file:
        ```bash
        cp .env.example .env
        ```
    *   Open the newly created `.env` file and **fill in your actual API keys** for OpenAI and Google Gemini. If you plan to use Deepgram, uncomment and set that key as well.
        ```bash
        # Example .env content (fill in YOUR_API_KEY_HERE)
        PORT=3000
        DB_HOST=postgres_db
        DB_PORT=5432
        DB_USER=user
        DB_PASSWORD=password
        DB_NAME=transcription_db
        OPENAI_API_KEY="sk-YOUR_OPENAI_API_KEY_HERE"
        GEMINI_API_KEY="AIzaSyYOUR_GEMINI_API_KEY_HERE"
        # DEEPGRAM_API_KEY="Token YOUR_DEEPGRAM_API_KEY_HERE" 
        ```

3.  **Build and Run Docker Containers:**
    *   From the `transcription-app` directory, navigate to the `infrastructure` directory:
        ```bash
        cd infrastructure
        ```
    *   Build the Docker images for the backend and set up the PostgreSQL database:
        ```bash
        docker-compose build
        ```
    *   Start the services in detached mode:
        ```bash
        docker-compose up -d
        ```
    *   This command will:
        *   Build the `backend` Docker image based on `backend/Dockerfile`.
        *   Pull the `postgres:16-alpine` image.
        *   Start the PostgreSQL container, creating the `transcription_db` database.
        *   Start the `backend` container, which will connect to the PostgreSQL container and automatically create the `transcriptions` table on its first run.

4.  **Verify Services:**
    *   Check if both containers are running:
        ```bash
        docker-compose ps
        ```
    *   You should see `backend` and `postgres_db` in the `Up` state.
    *   Access the frontend in your browser: `http://localhost:3000`
    *   Check the backend health endpoint: `http://localhost:3000/api/health` (should return `{"status":"ok","message":"Backend is running"}`).

5.  **View Logs:**
    *   To see real-time logs from the backend:
        ```bash
        docker-compose logs -f backend
        ```
    *   To see real-time logs from the database:
        ```bash
        docker-compose logs -f postgres_db
        ```

## AWS EC2 Deployment

Refer to `infrastructure/aws_deploy_notes.md` for detailed instructions on deploying this application to an AWS EC2 instance.

## Usage

1.  Open the application in your web browser (locally at `http://localhost:3000`).
2.  Choose your desired STT Service: "OpenAI Whisper", "Deepgram (Nova-3)", or "Google Gemini (Audio Description)".
3.  Click "Start Recording" to use your microphone (you'll see the waveform visualizer) or "Upload Audio File" to select a file from your computer.
4.  After recording/uploading, the audio will be sent to the backend for transcription and processing.
5.  The raw transcribed text, multispeaker output, detected topics, and the polished note (for Google Gemini) will appear in the respective text areas.

## Enhancements & Future Work

*   **Error Handling:** More robust error handling and user feedback.
*   **AWS S3 Integration:** Store audio files in AWS S3 instead of just processing on the fly (and local IndexedDB), and pass S3 URLs to STT services (especially useful for files larger than API direct upload limits).
*   **Authentication/Authorization:** Add user accounts and protect API endpoints.
*   **Streaming Transcription:** For real-time transcription, move from batch processing (MediaRecorder `onstop`) to WebSockets for services that support streaming (like Deepgram or some Gemini APIs).
*   **Advanced Gemini Features:** Explore more of Gemini's LLM capabilities for action item extraction, more nuanced summaries, or even inferring speaker separation based on conversational patterns from the raw transcript.
*   **Frontend Framework:** Consider a framework like React, Vue, or Angular for more complex UI management and state handling, especially if the app grows.
*   **Scalability:** For high traffic, consider AWS ECS/EKS, Fargate, or Lambda for the backend, and AWS RDS for the database.
*   **Monitoring & Logging:** Integrate with AWS CloudWatch, Sentry, etc.
*   **CI/CD:** Automate deployment with tools like GitHub Actions, GitLab CI, AWS CodePipeline.
EOF

echo "All files generated successfully in the '$APP_DIR' directory."
echo "Navigate into '$APP_DIR', copy '.env.example' to '.env', and fill in your API keys."
echo "Then, from the 'infrastructure' directory within '$APP_DIR', run 'docker-compose build' and 'docker-compose up -d' to start the application."
echo "You can access the application at http://localhost:3000"

```

---

**How to Use the Script:**

1.  **Save the script:** Copy the entire bash script content above and save it to a file named `setup_transcription_app.sh` (or any `.sh` name) in your desired location.
2.  **Make it executable:** Open your terminal or Git Bash and navigate to the directory where you saved the script. Then, run:
    ```bash
    chmod +x setup_transcription_app.sh
    ```
3.  **Run the script:**
    ```bash
    ./setup_transcription_app.sh
    ```
    This will create the `transcription-app` directory and populate all the files within it.
4.  **Configure `.env`:**
    Once the script finishes, `cd transcription-app` and then `cp .env.example .env`. Open the `.env` file and replace `"sk-YOUR_OPENAI_API_KEY_HERE"` and `"AIzaSyYOUR_GEMINI_API_KEY_HERE"` (and optionally Deepgram) with your actual API keys.
5.  **Start Docker Compose:**
    From the `transcription-app` directory, navigate to `infrastructure`:
    ```bash
    cd infrastructure
    ```
    Then, build and run the Docker containers:
    ```bash
    docker-compose build
    docker-compose up -d
    ```
6.  **Access the application:** Open your web browser and go to `http://localhost:3000`.

This setup provides a robust foundation for your transcription application, separating frontend and backend concerns, and preparing for production deployment on AWS with Docker.
