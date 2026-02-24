# 🚀 Connect+

Plataforma gamificada de engajamento interno com sistema de ilhas, XP, ranking e painel administrativo.

Projeto MVP utilizando:

- Frontend: HTML + Tailwind + JS
- Backend: FastAPI (Python)
- Banco de Dados: PostgreSQL
- Autenticação: JWT
- Hash de senha: bcrypt

---

# 📁 Estrutura do Projeto
Connect+
│
├── backend/
│ ├── app/
│ │ └── main.py
│ ├── .venv/
│ └── requirements.txt
│
├── js/
│ └── auth.js
│
├── index.html
├── register.html
├── home.html
├── admin.html
└── README.md


---

# ⚙️ Requisitos

- Python 3.10+
- PostgreSQL rodando na porta 5432
- Node NÃO é necessário
- Extensão Live Server (VSCode)

---

# 🐍 Como Rodar o Backend (API)

### 1️⃣ Entrar na pasta backend
cd Connect+/backend

### 2️⃣ Criar ambiente virtual (se ainda não existir)
python -m venv .venv

### 3️⃣ Ativar o ambiente virtual

Windows PowerShell:
..venv\Scripts\activate

- Se der erro de política de execução:
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser


Depois ative novamente.

---

### 4️⃣ Instalar dependências
pip install -r requirements.txt

- Se necessário:
pip install "passlib[bcrypt]==1.7.4" "bcrypt==3.2.2"
pip install email-validator


---

### 5️⃣ Rodar a API
python -m uvicorn app.main:app --reload --port 8000


Se tudo estiver correto, aparecerá:
Uvicorn running on http://127.0.0.1:8000

http://127.0.0.1:5500/Connect+/index.html
