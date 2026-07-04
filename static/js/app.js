// Lucent — frontend logic
const API = "/api/transactions";

// Small, cohesive palette for category segments
const CATEGORY_COLORS = [
    "#0A93E4", "#6366F1", "#14B8A6", "#F59E0B",
    "#EC4899", "#8B5CF6", "#10B981", "#F04463",
];
const CATEGORY_ICONS = {
    housing: "🏠", food: "🍽️", utilities: "💡", transport: "🚌",
    entertainment: "🎬", health: "❤️", salary: "💼", freelance: "✳️",
};

const el = (id) => document.getElementById(id);
const fmt = (n) =>
    (n < 0 ? "-" : "") + "$" + Math.abs(n).toLocaleString("en-US", {
        minimumFractionDigits: 2, maximumFractionDigits: 2,
    });

let selectedType = "EXPENSE";
let cache = [];

/* ---------- type toggle ---------- */
const toggle = document.querySelector(".toggle");
document.querySelectorAll(".toggle__btn").forEach((btn) => {
    btn.addEventListener("click", () => {
        selectedType = btn.dataset.type;
        toggle.dataset.active = selectedType;
        document.querySelectorAll(".toggle__btn").forEach((b) =>
            b.classList.toggle("is-active", b === btn));
    });
});

/* ---------- animated number ---------- */
function animateValue(node, to) {
    const from = parseFloat(node.dataset.val || "0");
    node.dataset.val = to;
    const start = performance.now();
    const dur = 550;
    const reduce = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    if (reduce) { node.textContent = fmt(to); return; }
    function step(now) {
        const t = Math.min((now - start) / dur, 1);
        const eased = 1 - Math.pow(1 - t, 3);
        node.textContent = fmt(from + (to - from) * eased);
        if (t < 1) requestAnimationFrame(step);
    }
    requestAnimationFrame(step);
}

/* ---------- rendering ---------- */
function renderSummary(income, expense) {
    animateValue(el("balanceValue"), income - expense);
    el("incomeValue").textContent = fmt(income);
    el("expenseValue").textContent = fmt(expense);
}

function renderBreakdown(txns) {
    const expenses = txns.filter((t) => t.type === "EXPENSE");
    const byCat = {};
    for (const t of expenses) byCat[t.category] = (byCat[t.category] || 0) + Number(t.amount);

    const entries = Object.entries(byCat).sort((a, b) => b[1] - a[1]);
    const total = entries.reduce((s, [, v]) => s + v, 0);
    const bar = el("breakdownBar");
    const legend = el("breakdownLegend");
    bar.innerHTML = "";
    legend.innerHTML = "";
    el("breakdownTotal").textContent = total ? fmt(total) + " spent" : "";

    if (!total) {
        bar.innerHTML = `<div class="bar__seg" style="flex:1;background:rgba(255,255,255,0.06)"></div>`;
        return;
    }
    entries.forEach(([cat, val], i) => {
        const color = CATEGORY_COLORS[i % CATEGORY_COLORS.length];
        const seg = document.createElement("div");
        seg.className = "bar__seg";
        seg.style.flexGrow = val;
        seg.style.background = color;
        seg.title = `${cat}: ${fmt(val)}`;
        bar.appendChild(seg);

        const li = document.createElement("li");
        li.className = "legend__item";
        li.innerHTML =
            `<span class="legend__dot" style="background:${color}"></span>` +
            `${cat} <span class="legend__amt">${fmt(val)}</span>`;
        legend.appendChild(li);
    });
}

function renderList(txns) {
    const list = el("txList");
    list.innerHTML = "";
    el("txCount").textContent = txns.length ? `${txns.length} total` : "";
    el("emptyState").hidden = txns.length > 0;

    for (const t of txns) {
        const li = document.createElement("li");
        li.className = "tx";
        li.dataset.id = t.id;
        const isIn = t.type === "INCOME";
        const icon = CATEGORY_ICONS[t.category.toLowerCase()] || (isIn ? "💰" : "💳");
        const date = new Date(t.date).toLocaleDateString("en-US", { month: "short", day: "numeric" });
        li.innerHTML = `
            <div class="tx__icon">${icon}</div>
            <div class="tx__main">
                <div class="tx__desc"></div>
                <div class="tx__meta"></div>
            </div>
            <div class="tx__amt ${isIn ? "tx__amt--in" : "tx__amt--out"}">
                ${isIn ? "+" : "−"}${fmt(Number(t.amount))}
            </div>
            <button class="tx__del" aria-label="Delete transaction">✕</button>`;
        // set text safely (avoid HTML injection from user input)
        li.querySelector(".tx__desc").textContent = t.description;
        li.querySelector(".tx__meta").textContent = `${t.category} · ${date}`;
        li.querySelector(".tx__del").addEventListener("click", () => removeTx(t.id, li));
        list.appendChild(li);
    }
}

function render() {
    const income = cache.filter((t) => t.type === "INCOME").reduce((s, t) => s + Number(t.amount), 0);
    const expense = cache.filter((t) => t.type === "EXPENSE").reduce((s, t) => s + Number(t.amount), 0);
    renderSummary(income, expense);
    renderBreakdown(cache);
    renderList(cache);
}

/* ---------- data ---------- */
async function load() {
    try {
        const res = await fetch(API);
        if (!res.ok) throw new Error("Could not load transactions");
        cache = await res.json();
        render();
    } catch (e) {
        el("formError").textContent = "Couldn't reach the server. Is the app running?";
    }
}

async function addTx(payload) {
    const res = await fetch(API, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload),
    });
    if (res.status === 400 || res.status === 422) throw new Error("Please fill every field with valid values.");
    if (!res.ok) throw new Error("Something went wrong saving that.");
    return res.json();
}

async function removeTx(id, node) {
    node.classList.add("is-leaving");
    try {
        await fetch(`${API}/${id}`, { method: "DELETE" });
        cache = cache.filter((t) => t.id !== id);
        setTimeout(render, 260);
    } catch {
        node.classList.remove("is-leaving");
        el("formError").textContent = "Couldn't delete that one.";
    }
}

/* ---------- submit ---------- */
el("txForm").addEventListener("submit", async (e) => {
    e.preventDefault();
    el("formError").textContent = "";
    const btn = el("submitBtn");
    const payload = {
        description: el("description").value.trim(),
        amount: parseFloat(el("amount").value),
        type: selectedType,
        category: (el("category").value.trim() || "General"),
        date: el("date").value || new Date().toISOString().slice(0, 10),
    };
    if (!payload.description || !(payload.amount > 0)) {
        el("formError").textContent = "Add a description and an amount above zero.";
        return;
    }
    btn.disabled = true;
    try {
        const saved = await addTx(payload);
        cache.unshift(saved);
        cache.sort((a, b) => (b.date < a.date ? -1 : b.date > a.date ? 1 : b.id - a.id));
        render();
        e.target.reset();
        setDefaultDate();
    } catch (err) {
        el("formError").textContent = err.message;
    } finally {
        btn.disabled = false;
    }
});

/* ---------- init ---------- */
function setDefaultDate() {
    el("date").value = new Date().toISOString().slice(0, 10);
}
function setPeriod() {
    el("periodLabel").textContent = new Date().toLocaleDateString("en-US", { month: "long", year: "numeric" });
}
toggle.dataset.active = selectedType;
setDefaultDate();
setPeriod();
load();
