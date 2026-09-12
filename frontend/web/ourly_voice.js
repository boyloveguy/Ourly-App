// Ourly Voice Engine: Web Speech API (Speech-to-Text & Text-to-Speech)
window.OurlyVoice = {
  recognition: null,
  isListening: false,
  isSpeaking: false,
  speechSynth: window.speechSynthesis,
  currentUtterance: null,

  // --- SPEECH-TO-TEXT (STT) ---
  startListening: function(options) {
    const SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition;
    if (!SpeechRecognition) {
      console.warn('[OurlyVoice] Web SpeechRecognition is not supported in this browser.');
      if (options && options.onError) options.onError('Trình duyệt không hỗ trợ nhận diện giọng nói.');
      return false;
    }

    try {
      if (this.recognition) {
        try { this.recognition.abort(); } catch (e) {}
      }

      this.recognition = new SpeechRecognition();
      this.recognition.lang = (options && options.lang) || 'vi-VN';
      this.recognition.continuous = true;
      this.recognition.interimResults = true;

      this.recognition.onstart = () => {
        this.isListening = true;
        console.log('[OurlyVoice] Listening started...');
        if (options && options.onStart) options.onStart();
      };

      this.recognition.onresult = (event) => {
        let interimTranscript = '';
        let finalTranscript = '';

        for (let i = event.resultIndex; i < event.results.length; ++i) {
          const item = event.results[i];
          if (item.isFinal) {
            finalTranscript += item[0].transcript;
          } else {
            interimTranscript += item[0].transcript;
          }
        }

        const text = finalTranscript || interimTranscript;
        if (text && options && options.onResult) {
          options.onResult(text.trim(), Boolean(finalTranscript));
        }
      };

      this.recognition.onerror = (event) => {
        console.warn('[OurlyVoice] Recognition error:', event.error);
        if (options && options.onError) options.onError(event.error);
      };

      this.recognition.onend = () => {
        this.isListening = false;
        console.log('[OurlyVoice] Listening ended.');
        if (options && options.onEnd) options.onEnd();
      };

      this.recognition.start();
      return true;
    } catch (err) {
      console.error('[OurlyVoice] startListening failed:', err);
      if (options && options.onError) options.onError(err.toString());
      return false;
    }
  },

  stopListening: function() {
    if (this.recognition) {
      try {
        this.recognition.stop();
      } catch (e) {}
      this.isListening = false;
    }
  },

  currentAudio: null,

  // --- TEXT-TO-SPEECH (TTS) ---
  speak: function(text, options) {
    // 1. Stop any currently playing speech or audio
    this.stopSpeaking();

    // 2. Clean markdown characters, URLs, and emojis for natural, fluent reading
    let cleanText = text
      .replace(/[*_#>`~]/g, '')
      .replace(/https?:\/\/\S+/g, '')
      .replace(/[•\-\–\—]/g, ' ')
      .replace(/[\u{1F300}-\u{1F9FF}]/gu, '')
      .replace(/[\u{2600}-\u{27BF}]/gu, '')
      .replace(/\s+/g, ' ')
      .trim();

    if (!cleanText) return false;

    // 3. Primary: Play high-fidelity authentic Vietnamese voice from Backend / Google TTS
    try {
      const backendUrl = 'https://apricot-freezable-chemicals.ngrok-free.dev/v1/voice/tts?text=' + encodeURIComponent(cleanText);
      const audio = new Audio(backendUrl);
      this.currentAudio = audio;

      audio.onplay = () => {
        this.isSpeaking = true;
        console.log('[OurlyVoice] Vietnamese TTS playback started...');
        if (options && options.onStart) options.onStart();
      };

      audio.onended = () => {
        this.isSpeaking = false;
        this.currentAudio = null;
        console.log('[OurlyVoice] Vietnamese TTS playback finished.');
        if (options && options.onEnd) options.onEnd();
      };

      audio.onerror = (err) => {
        console.warn('[OurlyVoice] Backend TTS audio error, falling back to direct stream / WebSpeech...', err);
        this.currentAudio = null;
        this._speakDirectGoogleOrWebSpeech(cleanText, options);
      };

      const playPromise = audio.play();
      if (playPromise !== undefined) {
        playPromise.catch((err) => {
          console.warn('[OurlyVoice] Play promise rejected, trying fallback...', err);
          this._speakDirectGoogleOrWebSpeech(cleanText, options);
        });
      }
      return true;
    } catch (e) {
      console.warn('[OurlyVoice] speak exception, falling back:', e);
      return this._speakDirectGoogleOrWebSpeech(cleanText, options);
    }
  },

  _speakDirectGoogleOrWebSpeech: function(cleanText, options) {
    // Try direct Google Translate Vietnamese audio stream
    try {
      const gUrl = 'https://translate.google.com/translate_tts?ie=UTF-8&q=' + encodeURIComponent(cleanText.substring(0, 200)) + '&tl=vi&client=tw-ob';
      const audio = new Audio(gUrl);
      this.currentAudio = audio;

      audio.onplay = () => {
        this.isSpeaking = true;
        if (options && options.onStart) options.onStart();
      };
      audio.onended = () => {
        this.isSpeaking = false;
        this.currentAudio = null;
        if (options && options.onEnd) options.onEnd();
      };
      audio.onerror = () => {
        this._speakWebSpeechFallback(cleanText, options);
      };

      const p = audio.play();
      if (p !== undefined) {
        p.catch(() => this._speakWebSpeechFallback(cleanText, options));
      }
      return true;
    } catch (_) {
      return this._speakWebSpeechFallback(cleanText, options);
    }
  },

  _speakWebSpeechFallback: function(cleanText, options) {
    if (!this.speechSynth) {
      if (options && options.onError) options.onError('Không hỗ trợ phát âm thanh.');
      return false;
    }

    // Look specifically for a Vietnamese male voice
    const voices = this.speechSynth.getVoices() || [];
    const viVoices = voices.filter(v => v.lang && (v.lang.toLowerCase().startsWith('vi') || v.lang.toLowerCase().includes('vie') || (v.name && v.name.toLowerCase().includes('vietnam'))));
    const maleVoice = viVoices.find(v => {
      const n = (v.name || '').toLowerCase();
      return n.includes('nam') || n.includes('male') || n.includes('minh') || n.includes('an') || n.includes('khoi');
    });
    if (maleVoice) {
      utterance.voice = maleVoice;
    } else if (viVoices.length > 0) {
      utterance.voice = viVoices[0];
    }
    utterance.rate = (options && options.rate) || 1.18;
    utterance.pitch = (options && options.pitch) || 0.96;

    utterance.onstart = () => {
      this.isSpeaking = true;
      if (options && options.onStart) options.onStart();
    };

    utterance.onend = () => {
      this.isSpeaking = false;
      this.currentUtterance = null;
      if (options && options.onEnd) options.onEnd();
    };

    utterance.onerror = (event) => {
      this.isSpeaking = false;
      this.currentUtterance = null;
      if (options && options.onError) options.onError(event);
    };

    this.currentUtterance = utterance;
    this.speechSynth.speak(utterance);
    return true;
  },

  stopSpeaking: function() {
    if (this.currentAudio) {
      try {
        this.currentAudio.pause();
        this.currentAudio.currentTime = 0;
      } catch (e) {}
      this.currentAudio = null;
    }
    if (this.speechSynth) {
      try {
        this.speechSynth.cancel();
      } catch (e) {}
    }
    this.isSpeaking = false;
    this.currentUtterance = null;
  }
};

// Event Bridge with Flutter dart:html
window.addEventListener('ourly_start_listening', (e) => {
  const detail = e.detail || {};
  window.OurlyVoice.startListening({
    lang: detail.lang || 'vi-VN',
    onStart: () => {
      window.dispatchEvent(new CustomEvent('ourly_speech_start'));
    },
    onResult: (text, isFinal) => {
      window.dispatchEvent(new CustomEvent('ourly_speech_result', { detail: { text: text, isFinal: isFinal } }));
    },
    onEnd: () => {
      window.dispatchEvent(new CustomEvent('ourly_speech_end'));
    },
    onError: (err) => {
      window.dispatchEvent(new CustomEvent('ourly_speech_error', { detail: err }));
    }
  });
});

window.addEventListener('ourly_stop_listening', () => {
  window.OurlyVoice.stopListening();
});

window.addEventListener('ourly_speak', (e) => {
  const detail = e.detail || {};
  window.OurlyVoice.speak(detail.text || '', {
    lang: detail.lang || 'vi-VN',
    onStart: () => {
      window.dispatchEvent(new CustomEvent('ourly_speaking_start'));
    },
    onEnd: () => {
      window.dispatchEvent(new CustomEvent('ourly_speaking_end'));
    },
    onError: (err) => {
      window.dispatchEvent(new CustomEvent('ourly_speaking_error', { detail: err }));
    }
  });
});

window.addEventListener('ourly_stop_speaking', () => {
  window.OurlyVoice.stopSpeaking();
});

