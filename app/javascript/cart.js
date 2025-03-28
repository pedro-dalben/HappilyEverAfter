// Função para inicializar os botões do carrinho
function initializeCartButtons() {
  // Selecionar todos os botões de adicionar ao carrinho
  const addToCartButtons = document.querySelectorAll('.add-to-cart-btn');

  // Adicionar event listener para cada botão
  addToCartButtons.forEach(button => {
    // Remover event listeners antigos para evitar duplicação
    button.removeEventListener('click', handleAddToCartProxy);
    // Adicionar o novo event listener
    button.addEventListener('click', handleAddToCartProxy);
  });
}

// Proxy function para garantir que o contexto seja mantido
function handleAddToCartProxy(e) {
  const itemId = this.getAttribute('data-item-id');
  handleAddToCart(e, itemId);
}

// Função para lidar com o clique no botão de adicionar ao carrinho
function handleAddToCart(e, itemId) {
  e.preventDefault();

  // Mostrar indicador de carregamento
  const button = e.target.closest('.add-to-cart-btn');
  const originalText = button.innerHTML;
  button.innerHTML = '<span class="inline-block animate-spin mr-2">⟳</span> Adicionando...';
  button.disabled = true;

  // Fazer requisição AJAX para adicionar ao carrinho
  fetch(`/gift-registry/add-to-cart/${itemId}`, {
    method: 'POST',
    headers: {
      'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content,
      'Accept': 'application/json'
    }
  })
  .then(response => response.json())
  .then(data => {
    // Atualizar o contador do carrinho
    updateCartCounter(data.cart_count);

    // Mostrar notificação de sucesso
    showToast(data.message);

    // Restaurar o botão
    setTimeout(() => {
      button.innerHTML = originalText;
      button.disabled = false;
    }, 500);
  })
  .catch(error => {
    console.error('Erro ao adicionar item ao carrinho:', error);
    // Restaurar o botão em caso de erro
    button.innerHTML = originalText;
    button.disabled = false;
  });
}

// Função para atualizar o contador do carrinho
function updateCartCounter(count) {
  const cartCounter = document.getElementById('cart-counter');

  if (cartCounter) {
    // Definir o texto antes de mostrar/esconder
    cartCounter.textContent = count;

    // Forçar a visibilidade do contador quando há itens
    if (count > 0) {
      cartCounter.style.display = 'flex';
    } else {
      cartCounter.style.display = 'none';
    }
  } else {
    console.error("Elemento cart-counter não encontrado");
  }
}

// Adicione esta função se ainda não tiver um método showToast definido
function showToast(message, duration = 3000) {
  const toast = document.getElementById('toast-notification');
  if (!toast) {
    console.error("Elemento toast-notification não encontrado");
    return;
  }

  const toastMessage = document.getElementById('toast-message');
  if (!toastMessage) {
    console.error("Elemento toast-message não encontrado");
    return;
  }

  // Set message
  toastMessage.textContent = message;

  // Show toast
  toast.style.display = 'block';

  // Trigger animation
  setTimeout(() => {
    toast.classList.remove('translate-y-24', 'opacity-0');
    toast.classList.add('translate-y-0', 'opacity-100');
  }, 10);

  // Hide after duration
  setTimeout(() => {
    toast.classList.remove('translate-y-0', 'opacity-100');
    toast.classList.add('translate-y-24', 'opacity-0');

    // Hide element after animation
    setTimeout(() => {
      toast.style.display = 'none';
    }, 300);
  }, duration);
}

// Inicializar assim que o DOM estiver pronto
document.addEventListener('DOMContentLoaded', function() {
  initializeCartButtons();
});

// Reinicializar após cada navegação do Turbo
document.addEventListener('turbo:load', function() {
  initializeCartButtons();
});

// Também reinicializar após renderização de frame do Turbo
document.addEventListener('turbo:frame-render', function() {
  initializeCartButtons();
});

// Adicionar ouvinte para o primeiro load
document.addEventListener('load', function() {
  initializeCartButtons();
});
