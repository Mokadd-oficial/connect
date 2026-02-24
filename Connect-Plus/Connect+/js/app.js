document.addEventListener("DOMContentLoaded", function () {

  // ============================
  // MISSÕES DO SISTEMA
  // ============================
  const missions = [
    { id: "M1", title: "Selecionar a sua área", points: 50, desc: "Escolha sua área de atuação.", status: "pending" },
    { id: "M2", title: "Fazer Voluntários", points: 70, desc: "Participe de iniciativas sociais.", status: "pending" },
    { id: "M3", title: "Fazer Certificações", points: 120, desc: "Conclua certificações recomendadas.", status: "pending" },
    { id: "M4", title: "Fazer o Compliance", points: 100, desc: "Realize os treinamentos obrigatórios.", status: "pending" },
    { id: "M5", title: "Conhecer o prédio", points: 40, desc: "Explore o prédio e seus setores.", status: "pending" },
    { id: "M6", title: "Conhecer Cases de Sucesso", points: 60, desc: "Veja histórias reais de clientes Oracle.", status: "pending" },
    { id: "M7", title: "Conhecer o Impacto Social", points: 70, desc: "Descubra como a Oracle gera impacto.", status: "pending" },
    { id: "M8", title: "Conhecer os seus Benefícios", points: 90, desc: "Conheça todos seus benefícios.", status: "pending" },
    { id: "M9", title: "Atividades de Bem Estar", points: 60, desc: "Pratique atividades para bem-estar.", status: "pending" }
  ];

  // ============================
  // GERAR CARDS NA PÁGINA
  // ============================
  const grid = document.getElementById("mission-grid");

  missions.forEach(m => {
    const card = document.createElement("div");

    card.className =
      "bg-card-light dark:bg-card-dark border border-primary/20 p-6 rounded-lg flex flex-col justify-between cursor-pointer hover:shadow-lg hover:border-primary/50 transition-all";
    card.dataset.status = m.status;

    card.innerHTML = `
      <div>
        <div class="flex justify-between items-start mb-2">
          <h3 class="text-lg font-bold">${m.title}</h3>
          <span class="bg-blue-100 dark:bg-blue-900/40 text-blue-700 dark:text-blue-300 text-xs px-2.5 py-1 rounded-full font-semibold">${m.points} pts</span>
        </div>
        <p class="text-sm text-text-light dark:text-text-dark">${m.desc}</p>
      </div>

      <button class="w-full mt-6 bg-primary text-white py-2.5 rounded-lg flex items-center justify-center gap-2 font-semibold text-sm" data-action="start">
        <span class="material-icons-outlined">play_circle</span> Iniciar Missão
      </button>
    `;

    grid.appendChild(card);
  });


  // ============================
  // FILTRO DE MISSÕES
  // ============================
  const filterButtons = document.querySelectorAll("[data-filter]");
  const cards = () => document.querySelectorAll("#mission-grid [data-status]");

  filterButtons.forEach(btn => {
    btn.addEventListener("click", () => {
      filterButtons.forEach(b => b.classList.remove("bg-primary", "text-white"));
      btn.classList.add("bg-primary", "text-white");

      const filter = btn.dataset.filter;

      cards().forEach(card => {
        card.style.display =
          filter === "all" || card.dataset.status === filter
            ? "flex"
            : "none";
      });
    });
  });


  // ============================
  // BOTÕES DE AÇÃO (INICIAR)
  // ============================
  document.addEventListener("click", function (e) {
    const btn = e.target.closest("[data-action='start']");
    if (!btn) return;

    const card = btn.closest("[data-status]");

    card.dataset.status = "progress"; // Atualiza o status

    btn.innerHTML = `
      <span class="material-icons-outlined">schedule</span> Em Progresso
    `;
    btn.classList.remove("bg-primary");
    btn.classList.add("bg-primary-light");
  });


  // ============================
  // MENU MOBILE
  // ============================
  const menuBtn = document.getElementById("menu-btn");
  const mobileMenu = document.getElementById("mobile-menu");

  menuBtn.addEventListener("click", () => {
    mobileMenu.classList.toggle("hidden");
  });

});
