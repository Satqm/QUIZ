<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>CA Final Prep Quiz</title>
  <style>
    :root {
      --primary: #2563eb;
      --primary-hover: #1d4ed8;
      --bg: #f8fafc;
      --card-bg: #ffffff;
      --text: #1e293b;
      --border: #e2e8f0;
      --correct: #22c55e;
      --wrong: #ef4444;
      --warning: #f59e0b;
    }

    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
      background-color: var(--bg);
      color: var(--text);
      display: flex;
      justify-content: center;
      align-items: center;
      min-height: 100vh;
      margin: 0;
      padding: 20px;
    }

    .quiz-container {
      background: var(--card-bg);
      width: 100%;
      max-width: 600px;
      border-radius: 12px;
      box-shadow: 0 4px 6px -1px rgb(0 0 0 / 0.1);
      padding: 30px;
    }

    #loading-screen {
      text-align: center;
      font-weight: 500;
      color: var(--primary);
    }

    #quiz-screen, #result-screen {
      display: none;
    }

    .header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 20px;
      font-size: 0.9rem;
      color: #64748b;
      border-bottom: 2px solid var(--border);
      padding-bottom: 10px;
    }

    .reset-btn {
      background: none;
      border: 1px solid var(--border);
      color: var(--text);
      padding: 5px 10px;
      border-radius: 6px;
      font-size: 0.8rem;
      cursor: pointer;
    }
    
    .reset-btn:hover {
      background: #f1f5f9;
      color: var(--wrong);
      border-color: var(--wrong);
    }

    .question {
      font-size: 1.25rem;
      font-weight: 600;
      margin-bottom: 25px;
      line-height: 1.5;
    }

    .options-grid {
      display: flex;
      flex-direction: column;
      gap: 12px;
    }

    .option-btn {
      background: var(--card-bg);
      border: 2px solid var(--border);
      padding: 15px;
      border-radius: 8px;
      font-size: 1rem;
      text-align: left;
      cursor: pointer;
      transition: all 0.2s;
      color: var(--text);
    }

    .option-btn:hover:not(:disabled) {
      border-color: var(--primary);
      background: #eff6ff;
    }

    .option-btn:disabled {
      cursor: default;
    }

    .option-btn.correct {
      background-color: #dcfce7;
      border-color: var(--correct);
      color: #166534;
    }

    .option-btn.wrong {
      background-color: #fee2e2;
      border-color: var(--wrong);
      color: #991b1b;
    }

    #next-btn, #restart-btn {
      margin-top: 25px;
      width: 100%;
      background: var(--primary);
      color: white;
      border: none;
      padding: 15px;
      border-radius: 8px;
      font-size: 1rem;
      font-weight: 600;
      cursor: pointer;
      display: none;
    }

    #next-btn:hover, #restart-btn:hover {
      background: var(--primary-hover);
    }

    .result-content {
      text-align: center;
    }

    .score-display {
      font-size: 3rem;
      font-weight: bold;
      color: var(--primary);
      margin: 20px 0;
    }
  </style>
</head>
<body>

  <div class="quiz-container">
    <div id="loading-screen">
      <h2 id="loading-text">Fetching CA Questions...</h2>
      <p>Connecting to database</p>
    </div>

    <div id="quiz-screen">
      <div class="header">
        <span id="question-tracker">Question 1 of X</span>
        <button class="reset-btn" onclick="clearProgressAndRestart()">Reset Quiz</button>
        <span id="score-tracker">Score: 0</span>
      </div>
      <div class="question" id="question-text">Loading question...</div>
      <div class="options-grid" id="options-container">
        <!-- Buttons injected here -->
      </div>
      <button id="next-btn">Next Question</button>
    </div>

    <div id="result-screen">
      <div class="result-content">
        <h2>Mock Test Complete!</h2>
        <div class="score-display" id="final-score">0 / 0</div>
        <p id="feedback-text">Great effort!</p>
        <button id="restart-btn">Take New Shuffled Test</button>
      </div>
    </div>
  </div>

  <script>
    const API_URL = 'https://docs.google.com/spreadsheets/d/e/2PACX-1vRAy0cnPqv6k1ckLp9wp9fRwh3kiMxZEHkEKTzPfDOKXOdfbxS3TdCWXzJZVTKydHUBEenaeUBYJsst/pub?output=csv';
    
    let questionsData = [];
    let currentIndex = 0;
    let score = 0;

    const loadingScreen = document.getElementById('loading-screen');
    const loadingText = document.getElementById('loading-text');
    const quizScreen = document.getElementById('quiz-screen');
    const resultScreen = document.getElementById('result-screen');
    const questionText = document.getElementById('question-text');
    const optionsContainer = document.getElementById('options-container');
    const nextBtn = document.getElementById('next-btn');
    const questionTracker = document.getElementById('question-tracker');
    const scoreTracker = document.getElementById('score-tracker');

    // Fisher-Yates Shuffle Algorithm to randomize questions
    function shuffleArray(array) {
      for (let i = array.length - 1; i > 0; i--) {
        const j = Math.floor(Math.random() * (i + 1));
        [array[i], array[j]] = [array[j], array[i]];
      }
    }

    // Save current state to browser storage
    function saveProgress() {
      const state = {
        questions: questionsData,
        currentIndex: currentIndex,
        score: score
      };
      localStorage.setItem('caQuizState', JSON.stringify(state));
    }

    // Initialize Quiz
    async function initQuiz() {
      // 1. Check if there is a saved session in progress
      const savedState = localStorage.getItem('caQuizState');
      
      if (savedState) {
        loadingText.textContent = "Resuming your saved session...";
        const state = JSON.parse(savedState);
        questionsData = state.questions;
        currentIndex = state.currentIndex;
        score = state.score;
        
        loadingScreen.style.display = 'none';
        
        if (currentIndex >= questionsData.length) {
          showResults(); // User already finished
        } else {
          quizScreen.style.display = 'block';
          loadQuestion();
        }
        return;
      }

      // 2. If no saved session, fetch fresh from CSV
      try {
        const response = await fetch(API_URL);
        const csvText = await response.text();
        
        questionsData = parseCSV(csvText);
        
        // Shuffle the newly fetched questions
        shuffleArray(questionsData);
        
        // Save initial state
        saveProgress();
        
        loadingScreen.style.display = 'none';
        
        if(questionsData.length > 0) {
          quizScreen.style.display = 'block';
          loadQuestion();
        } else {
          loadingScreen.innerHTML = "<h2>No questions found. Check your sheet.</h2>";
          loadingScreen.style.display = 'block';
        }
      } catch (error) {
        loadingScreen.innerHTML = "<h2>Error loading questions. Check console.</h2>";
        console.error("Fetch Error:", error);
      }
    }

    // Convert CSV text to JSON array
    function parseCSV(text) {
      const rows = text.split('\n').map(row => row.trim()).filter(row => row);
      const headers = rows[0].split(',').map(h => h.trim());
      const result = [];
      
      for (let i = 1; i < rows.length; i++) {
        const values = rows[i].match(/(?:\"([^\"]*(?:\"\"[^\"]*)*)\"|([^,]+))/g) || [];
        const record = {};
        for (let j = 0; j < headers.length; j++) {
          let val = values[j] ? values[j].trim() : "";
          if (val.startsWith('"') && val.endsWith('"')) {
             val = val.substring(1, val.length - 1).replace(/""/g, '"');
          }
          record[headers[j]] = val;
        }
        result.push(record);
      }
      return result;
    }

    function loadQuestion() {
      nextBtn.style.display = 'none';
      optionsContainer.innerHTML = '';
      
      // Update trackers based on saved state
      scoreTracker.textContent = `Score: ${score}`;
      questionTracker.textContent = `Question ${currentIndex + 1} of ${questionsData.length}`;
      
      const currentQ = questionsData[currentIndex];
      questionText.textContent = currentQ['Question'];

      const optionsMap = [
        { letter: 'A', text: currentQ['Option A'] },
        { letter: 'B', text: currentQ['Option B'] },
        { letter: 'C', text: currentQ['Option C'] },
        { letter: 'D', text: currentQ['Option D'] }
      ];

      optionsMap.forEach(opt => {
        if (!opt.text) return;

        const btn = document.createElement('button');
        btn.classList.add('option-btn');
        btn.textContent = `${opt.letter}. ${opt.text}`;
        
        btn.onclick = () => checkAnswer(opt.letter, btn);
        optionsContainer.appendChild(btn);
      });
    }

    function checkAnswer(selectedLetter, clickedBtn) {
      const currentQ = questionsData[currentIndex];
      const correctAnswer = String(currentQ['Correct Answer']).trim().toUpperCase();
      
      const allBtns = document.querySelectorAll('.option-btn');
      allBtns.forEach(btn => btn.disabled = true);

      if (selectedLetter === correctAnswer) {
        clickedBtn.classList.add('correct');
        score++;
        scoreTracker.textContent = `Score: ${score}`;
      } else {
        clickedBtn.classList.add('wrong');
        allBtns.forEach(btn => {
          if (btn.textContent.startsWith(correctAnswer + ".")) {
            btn.classList.add('correct');
          }
        });
      }
      
      nextBtn.style.display = 'block';
    }

    nextBtn.onclick = () => {
      currentIndex++;
      // Save progress every time we move to a new question
      saveProgress(); 
      
      if (currentIndex < questionsData.length) {
        loadQuestion();
      } else {
        showResults();
      }
    };

    function showResults() {
      quizScreen.style.display = 'none';
      resultScreen.style.display = 'block';
      
      document.getElementById('final-score').textContent = `${score} / ${questionsData.length}`;
      
      const percentage = (score / questionsData.length) * 100;
      const feedback = document.getElementById('feedback-text');
      
      if (percentage >= 80) feedback.textContent = "Excellent! You are exam ready.";
      else if (percentage >= 50) feedback.textContent = "Good effort, but room for review.";
      else feedback.textContent = "Time to revisit the study modules.";
      
      // Clear progress when test is completed naturally
      localStorage.removeItem('caQuizState');
    }

    // Force restart - clears storage and fetches fresh data
    function clearProgressAndRestart() {
      if(confirm("Are you sure you want to reset your progress? You will lose your current score.")) {
        localStorage.removeItem('caQuizState');
        location.reload(); // Reloads the page to start fresh
      }
    }

    // Restart button at the end of the quiz
    document.getElementById('restart-btn').onclick = () => {
      localStorage.removeItem('caQuizState');
      location.reload(); 
    };

    // Start App
    initQuiz();
  </script>
</body>
</html>
