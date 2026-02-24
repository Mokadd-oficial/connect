let score = 0;
const icones = document.querySelectorAll('.icone');
const flashcard = document.getElementById('flashcard');
const cardBox = document.getElementById('cardBox');
const perguntaEl = document.getElementById('pergunta');
const respostaEl = document.getElementById('resposta');
const scoreEl = document.getElementById('score');
const opcoesContainer = document.getElementById('opcoes-container');

let iconeAtual = null;
let respostaCorreta = '';
let explicacaoAtual = '';

icones.forEach(icone => {
    icone.addEventListener('click', () => {
        iconeAtual = icone;
        const dados = icone.dataset;
        
        respostaCorreta = dados.correta;
        explicacaoAtual = dados.explicacao;
        perguntaEl.textContent = dados.pergunta;
        
        opcoesContainer.innerHTML = '';
        const opcoes = JSON.parse(dados.opcoes);

        opcoes.forEach(opt => {
            const btn = document.createElement('button');
            btn.className = 'opcao-resposta';
            btn.textContent = opt;
            btn.onclick = () => validar(opt, btn);
            opcoesContainer.appendChild(btn);
        });

        flashcard.style.display = 'flex';
        cardBox.classList.remove('flipped');
    });
});

function validar(selecionada, botao) {
    const todosBotões = document.querySelectorAll('.opcao-resposta');
    
    if (selecionada === respostaCorreta) {
        botao.style.background = '#28a745';
        botao.style.color = 'white';
        score += 10;
        scoreEl.textContent = score;
        
        if (!iconeAtual.classList.contains('respondido')) {
            iconeAtual.classList.add('respondido');
            iconeAtual.querySelector('i').className = 'fas fa-check-circle';
        }

        setTimeout(() => {
            respostaEl.textContent = explicacaoAtual;
            cardBox.classList.add('flipped');
        }, 600);
    } else {
        botao.style.background = '#dc3545';
        botao.style.color = 'white';
        botao.classList.add('shake'); // Opcional: adicionar animação de erro no CSS
        setTimeout(() => {
            botao.style.background = '#f8fbff';
            botao.style.color = '#003566';
        }, 1000);
    }
}

document.getElementById('btnFechar').onclick = () => flashcard.style.display = 'none';
document.getElementById('btnVoltar').onclick = () => flashcard.style.display = 'none';