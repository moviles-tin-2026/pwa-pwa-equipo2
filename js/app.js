const products = [
    {
        id: 1,
        name: "Café americano",
        sku: "CAF-001",
        category: "Bebidas calientes",
        price: 45,
        stock: 30,
        emoji: "☕"
    },
    {
        id: 2,
        name: "Capuchino",
        sku: "CAP-002",
        category: "Bebidas calientes",
        price: 65,
        stock: 12,
        emoji: "🥛"
    },
    {
        id: 3,
        name: "Latte vainilla",
        sku: "LAT-003",
        category: "Bebidas calientes",
        price: 70,
        stock: 8,
        emoji: "☕"
    },
    {
        id: 4,
        name: "Frappé moka",
        sku: "FRP-004",
        category: "Bebidas frías",
        price: 85,
        stock: 5,
        emoji: "🧋"
    },
    {
        id: 5,
        name: "Croissant",
        sku: "PAN-005",
        category: "Panadería",
        price: 42,
        stock: 18,
        emoji: "🥐"
    },
    {
        id: 6,
        name: "Muffin chocolate",
        sku: "PAN-006",
        category: "Panadería",
        price: 48,
        stock: 10,
        emoji: "🧁"
    },
    {
        id: 7,
        name: "Sandwich de jamón",
        sku: "COM-007",
        category: "Comida",
        price: 95,
        stock: 7,
        emoji: "🥪"
    },
    {
        id: 8,
        name: "Cheesecake",
        sku: "POS-008",
        category: "Postres",
        price: 75,
        stock: 4,
        emoji: "🍰"
    }
];

let cart = JSON.parse(localStorage.getItem("pyme_cart")) || [];
let history = JSON.parse(localStorage.getItem("pyme_history")) || [];
let selectedCategory = "Todas";
let deferredPrompt = null;

const productGrid = document.getElementById("productGrid");
const productCounter = document.getElementById("productCounter");
const searchInput = document.getElementById("searchInput");
const categoryBtn = document.getElementById("categoryBtn");
const categoryLabel = document.getElementById("categoryLabel");
const categoryMenu = document.getElementById("categoryMenu");
const saleItems = document.getElementById("saleItems");
const subtotalText = document.getElementById("subtotalText");
const taxText = document.getElementById("taxText");
const totalText = document.getElementById("totalText");
const completeSaleBtn = document.getElementById("completeSaleBtn");
const clearSaleBtn = document.getElementById("clearSaleBtn");
const clearHistoryBtn = document.getElementById("clearHistoryBtn");
const salesHistory = document.getElementById("salesHistory");
const messageBox = document.getElementById("messageBox");
const installBtn = document.getElementById("installBtn");

function money(value) {
    return `$${value.toFixed(2)}`;
}

function saveData() {
    localStorage.setItem("pyme_cart", JSON.stringify(cart));
    localStorage.setItem("pyme_history", JSON.stringify(history));
}

function showMessage(text, type = "success") {
    messageBox.textContent = text;
    messageBox.className = `message ${type}`;

    setTimeout(() => {
        messageBox.textContent = "";
        messageBox.className = "message";
    }, 2600);
}

function getAvailableStock(productId) {
    const product = products.find((item) => item.id === productId);
    const cartItem = cart.find((item) => item.id === productId);

    return product.stock - (cartItem ? cartItem.quantity : 0);
}

function renderCategories() {
    const categories = ["Todas", ...new Set(products.map((product) => product.category))];

    categoryMenu.innerHTML = categories
        .map((category) => {
            return `<button type="button" data-category="${category}">${category}</button>`;
        })
        .join("");

    categoryMenu.querySelectorAll("button").forEach((button) => {
        button.addEventListener("click", () => {
            selectedCategory = button.dataset.category;
            categoryLabel.textContent = selectedCategory;
            categoryMenu.classList.add("hidden");
            renderProducts();
        });
    });
}

function renderProducts() {
    const search = searchInput.value.toLowerCase().trim();

    const filteredProducts = products.filter((product) => {
        const matchesSearch =
            product.name.toLowerCase().includes(search) ||
            product.sku.toLowerCase().includes(search) ||
            product.category.toLowerCase().includes(search);

        const matchesCategory =
            selectedCategory === "Todas" || product.category === selectedCategory;

        return matchesSearch && matchesCategory;
    });

    productCounter.textContent = `${filteredProducts.length} productos`;

    productGrid.innerHTML = filteredProducts
        .map((product) => {
            const available = getAvailableStock(product.id);
            const lowStock = available <= 5;
            const inCart = cart.some((item) => item.id === product.id);

            return `
        <button class="product-card ${lowStock ? "low" : ""} ${inCart ? "selected" : ""}" data-id="${product.id}">
          <div class="product-top">
            <span class="product-emoji">${product.emoji}</span>
            <span class="stock-label">${lowStock ? "Bajo stock" : "Stock"}: ${available}</span>
          </div>

          <div>
            <h3>${product.name}</h3>
            <p>${product.sku} · ${product.category}</p>
            <div class="product-price">${money(product.price)}</div>
          </div>
        </button>
      `;
        })
        .join("");

    productGrid.querySelectorAll(".product-card").forEach((card) => {
        card.addEventListener("click", () => {
            addToCart(Number(card.dataset.id));
        });
    });
}

function addToCart(productId) {
    const product = products.find((item) => item.id === productId);
    const cartItem = cart.find((item) => item.id === productId);

    if (!product) return;

    if (getAvailableStock(productId) <= 0) {
        showMessage("No hay stock disponible para este producto.", "error");
        return;
    }

    if (cartItem) {
        cartItem.quantity += 1;
    } else {
        cart.push({
            id: product.id,
            quantity: 1
        });
    }

    saveData();
    renderAll();
}

function removeFromCart(productId) {
    cart = cart.filter((item) => item.id !== productId);
    saveData();
    renderAll();
}

function changeQuantity(productId, change) {
    const cartItem = cart.find((item) => item.id === productId);

    if (!cartItem) return;

    const product = products.find((item) => item.id === productId);
    const newQuantity = cartItem.quantity + change;

    if (newQuantity <= 0) {
        removeFromCart(productId);
        return;
    }

    if (newQuantity > product.stock) {
        showMessage("No puedes vender más piezas que el stock disponible.", "error");
        return;
    }

    cartItem.quantity = newQuantity;
    saveData();
    renderAll();
}

function renderCart() {
    if (cart.length === 0) {
        saleItems.innerHTML = `
      <div class="empty-sale">
        Selecciona un producto para iniciar la venta.
      </div>
    `;

        completeSaleBtn.disabled = true;
    } else {
        completeSaleBtn.disabled = false;

        saleItems.innerHTML = cart
            .map((cartItem) => {
                const product = products.find((item) => item.id === cartItem.id);
                const remaining = product.stock - cartItem.quantity;

                return `
          <div class="sale-product">
            <div class="product-icon">${product.emoji}</div>

            <div class="sale-info">
              <h3>${product.name}</h3>
              <p>${money(product.price)} c/u</p>
              <small>Stock restante: ${remaining}</small>
            </div>

            <div class="quantity-control">
              <button type="button" data-action="minus" data-id="${product.id}">-</button>
              <span>${cartItem.quantity}</span>
              <button type="button" data-action="plus" data-id="${product.id}">+</button>
            </div>
          </div>
        `;
            })
            .join("");
    }

    saleItems.querySelectorAll("button").forEach((button) => {
        button.addEventListener("click", () => {
            const id = Number(button.dataset.id);
            const action = button.dataset.action;

            if (action === "plus") {
                changeQuantity(id, 1);
            } else {
                changeQuantity(id, -1);
            }
        });
    });

    renderTotals();
}

function renderTotals() {
    const subtotal = cart.reduce((sum, cartItem) => {
        const product = products.find((item) => item.id === cartItem.id);
        return sum + product.price * cartItem.quantity;
    }, 0);

    const tax = subtotal * 0.15;
    const total = subtotal + tax;

    subtotalText.textContent = money(subtotal);
    taxText.textContent = money(tax);
    totalText.textContent = money(total);
}

function completeSale() {
    if (cart.length === 0) {
        showMessage("Agrega productos antes de completar la venta.", "error");
        return;
    }

    const saleTotal = cart.reduce((sum, cartItem) => {
        const product = products.find((item) => item.id === cartItem.id);
        return sum + product.price * cartItem.quantity * 1.15;
    }, 0);

    const saleItemsText = cart.map((cartItem) => {
        const product = products.find((item) => item.id === cartItem.id);
        product.stock -= cartItem.quantity;
        return `${product.name} x${cartItem.quantity}`;
    });

    history.unshift({
        id: Date.now(),
        items: saleItemsText,
        total: saleTotal,
        date: new Date().toLocaleString("es-MX")
    });

    cart = [];
    saveData();
    renderAll();
    showMessage("Venta registrada correctamente.", "success");
}

function renderHistory() {
    if (history.length === 0) {
        salesHistory.innerHTML = `
      <div class="empty-sale">
        Todavía no hay ventas recientes.
      </div>
    `;
        return;
    }

    salesHistory.innerHTML = history
        .map((sale) => {
            return `
        <article class="history-item">
          <div>
            <h3>${sale.items.join(", ")}</h3>
            <p>${sale.date}</p>
          </div>

          <strong>${money(sale.total)}</strong>
        </article>
      `;
        })
        .join("");
}

function renderAll() {
    renderProducts();
    renderCart();
    renderHistory();
}

searchInput.addEventListener("input", renderProducts);

categoryBtn.addEventListener("click", () => {
    categoryMenu.classList.toggle("hidden");
});

document.getElementById("focusSearch").addEventListener("click", () => {
    searchInput.focus();
});

document.getElementById("scanBtn").addEventListener("click", () => {
    showMessage("Simulación: lector de código activado.", "success");
});

document.getElementById("userBtn").addEventListener("click", () => {
    showMessage("Sesión activa: administrador.", "success");
});

clearSaleBtn.addEventListener("click", () => {
    cart = [];
    saveData();
    renderAll();
    showMessage("Venta actual vaciada.", "success");
});

clearHistoryBtn.addEventListener("click", () => {
    history = [];
    saveData();
    renderHistory();
    showMessage("Historial limpiado.", "success");
});

completeSaleBtn.addEventListener("click", completeSale);

document.querySelectorAll(".bottom-nav button").forEach((button) => {
    button.addEventListener("click", () => {
        document.querySelectorAll(".bottom-nav button").forEach((item) => {
            item.classList.remove("active");
        });

        button.classList.add("active");
        showMessage(`Vista ${button.dataset.view} seleccionada.`, "success");
    });
});

window.addEventListener("beforeinstallprompt", (event) => {
    event.preventDefault();
    deferredPrompt = event;
    installBtn.classList.remove("hidden");
});

installBtn.addEventListener("click", async () => {
    if (!deferredPrompt) return;

    deferredPrompt.prompt();
    await deferredPrompt.userChoice;

    deferredPrompt = null;
    installBtn.classList.add("hidden");
});

if ("serviceWorker" in navigator) {
    window.addEventListener("load", () => {
        navigator.serviceWorker.register("sw.js");
    });
}

renderCategories();
renderAll();