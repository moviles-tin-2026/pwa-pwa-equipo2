// ==========================================
//  ESTADO GLOBAL DE FILTRADO
// ==========================================
let currentCategory = 'todos';

function toggleFilterMenu() {
    const dropdown = document.getElementById('filterDropdown');
    dropdown.classList.toggle('show');
}

function setCategory(category, element) {
    currentCategory = category;
    document.querySelectorAll('.filter-option').forEach(opt => opt.classList.remove('active'));
    element.classList.add('active');
    
    document.getElementById('filterDropdown').classList.remove('show');
    document.getElementById('activeFilterBadge').innerText = `FILTRADO POR: ${category.toUpperCase()}`;
    
    filterProducts();
}

function filterProducts() {
    const searchInput = document.getElementById('searchInput').value.toLowerCase();
    const productItems = document.querySelectorAll('.product-item');
    const noResultsMessage = document.getElementById('noResultsMessage');
    const collapseBtn = document.getElementById('collapseBtn');
    
    let visibleCount = 0;
    let lowStockCount = 0;

    productItems.forEach(item => {
        const productName = item.querySelector('h3').innerText.toLowerCase();
        const productSku = item.querySelector('.sku').innerText.toLowerCase();
        const itemCategory = item.getAttribute('data-category');
        const isLowStock = item.getAttribute('data-stock') === 'low';

        const matchesSearch = productName.includes(searchInput) || productSku.includes(searchInput);
        const matchesCategory = currentCategory === 'todos' || itemCategory === currentCategory;

        if (matchesSearch && matchesCategory) {
            item.style.display = 'flex';
            visibleCount++;
            if (isLowStock) lowStockCount++;
        } else {
            item.style.display = 'none';
        }
    });

    document.getElementById('totalItemsCount').innerText = visibleCount;
    document.getElementById('lowStockCount').innerText = lowStockCount;

    if (visibleCount === 0) {
        noResultsMessage.style.display = 'block';
    } else {
        noResultsMessage.style.display = 'none';
    }

    if (searchInput !== '' || currentCategory !== 'todos') {
        if(collapseBtn) collapseBtn.style.display = 'block';
    } else {
        if(collapseBtn) collapseBtn.style.display = 'none';
    }
}

function resetFilters() {
    document.getElementById('searchInput').value = '';
    currentCategory = 'todos';
    document.querySelectorAll('.filter-option').forEach(opt => opt.classList.remove('active'));
    document.querySelector('.filter-option').classList.add('active');
    document.getElementById('activeFilterBadge').innerText = "FILTRADO POR: TODOS";
    filterProducts();
}

window.onclick = function(event) {
    if (!event.target.matches('#filterMenuBtn')) {
        const dropdown = document.getElementById('filterDropdown');
        if (dropdown && dropdown.classList.contains('show')) {
            dropdown.classList.remove('show');
        }
    }
}

// ==========================================
//  ANIMACIÓN CANVAS: GRANOS DE CAFÉ OPTIMIZADOS
// ==========================================
const canvas = document.getElementById('coffeeBackground');
const ctx = canvas.getContext('2d');

function resizeCanvas() {
    canvas.width = window.innerWidth;
    canvas.height = window.innerHeight;
}
window.addEventListener('resize', resizeCanvas);
resizeCanvas();

const grains = [];
const totalGrains = 20; 

class CoffeeGrain {
    constructor() {
        this.reset();
        this.y = Math.random() * canvas.height; 
        this.x = Math.random() * canvas.width;
    }

    reset() {
        this.x = Math.random() * (canvas.width + 200) - 200;
        this.y = -40;
        this.size = Math.random() * 10 + 14; 
        this.speedY = Math.random() * 0.5 + 0.4;  
        this.speedX = this.speedY * 0.5;          
        this.angle = Math.random() * Math.PI * 2;
        this.rotationSpeed = (Math.random() - 0.5) * 0.005;
    }

    update() {
        this.y += this.speedY;
        this.x += this.speedX;
        this.angle += this.rotationSpeed;
        
        if (this.y > canvas.height + 40 || this.x > canvas.width + 40) {
            this.reset();
        }
    }

    draw() {
        const progress = Math.min(Math.max(this.y / canvas.height, 0), 1);
        
        const r = Math.floor(31 + (198 * progress));
        const g = Math.floor(12 + (201 * progress));
        const b = Math.floor(4 + (199 * progress));
        
        ctx.save();
        ctx.translate(this.x, this.y);
        ctx.rotate(this.angle);
        
        ctx.beginPath();
        ctx.fillStyle = `rgba(${r}, ${g}, ${b}, 0.18)`; 
        ctx.ellipse(0, 0, this.size, this.size * 0.68, 0, 0, Math.PI * 2);
        ctx.fill();

        ctx.beginPath();
        ctx.strokeStyle = `rgba(${Math.max(0, r - 30)}, ${Math.max(0, g - 20)}, ${Math.max(0, b - 15)}, 0.15)`;
        ctx.lineWidth = 2;
        ctx.moveTo(-this.size, 0);
        ctx.quadraticCurveTo(0, this.size * 0.15, this.size, 0);
        ctx.stroke();

        ctx.restore();
    }
}

for (let i = 0; i < totalGrains; i++) {
    grains.push(new CoffeeGrain());
}

function animate() {
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    grains.forEach(grain => {
        grain.update();
        grain.draw();
    });
    requestAnimationFrame(animate);
}

// ==========================================
//  NUEVO: INTERACCIONES DE LA VENTANA MODAL
// ==========================================
const modal = document.getElementById('addProductModal');
const openModalBtn = document.getElementById('openModalBtn');
const closeModalBtn = document.getElementById('closeModalBtn');
const newProductForm = document.getElementById('newProductForm');

// Abrir modal al presionar el FAB extensible
openModalBtn.addEventListener('click', () => {
    modal.classList.add('show');
});

// Cerrar modal al dar clic a la equis 'X'
closeModalBtn.addEventListener('click', () => {
    modal.classList.remove('show');
});

// Cerrar modal alternativo al dar un clic al fondo desenfocado
modal.addEventListener('click', (e) => {
    if (e.target === modal) {
        modal.classList.remove('show');
    }
});

// Simulación de guardado y captura de datos del formulario
newProductForm.addEventListener('submit', () => {
    const name = document.getElementById('prodName').value;
    const sku = document.getElementById('prodSku').value;
    const category = document.getElementById('prodCategory').value;
    const price = parseFloat(document.getElementById('prodPrice').value).toFixed(2);
    const stock = parseInt(document.getElementById('prodStock').value);

    console.log("Guardando nuevo insumo en PyME-Sync:", { name, sku, category, price, stock });
    
    // Aquí puedes meter la lógica de inserción al DOM si la requieres más adelante
    alert(`Insumo "${name}" registrado con éxito.`);
    
    // Limpieza e inhabilitación de vista
    newProductForm.reset();
    modal.classList.remove('show');
    filterProducts();
});

// Inicialización general
window.onload = function() {
    filterProducts();
    animate();
};