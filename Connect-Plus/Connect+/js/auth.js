console.log("auth.js carregou ✅");

function getUser() {
  return JSON.parse(localStorage.getItem("cp_user"));
}

function requireAuth() {
  const user = getUser();
  if (!user) {
    window.location.href = "index.html";
  }
}

function requireAdmin() {
  const user = getUser();
  if (!user || user.role !== "admin") {
    window.location.href = "home.html";
  }
}

function showAdminLink() {
  const user = getUser();
  if (user?.role === "admin") {
    const adminLink = document.getElementById("admin-link");
    if (adminLink) adminLink.classList.remove("hidden");
  }
}