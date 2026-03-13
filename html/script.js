// ==================== RESOURCE NAME HELPER ====================
const nativeGetParentResourceName = window.GetParentResourceName;

function getResourceName() {
    if (typeof nativeGetParentResourceName === 'function') {
        return nativeGetParentResourceName();
    }
    return 'phils-bible';
}

// ==================== STATE MANAGEMENT ====================
let currentMenuType = 'main';
let currentMenuData = null;
let inputCallback = null;
let sermonTimer = null;
let sermonTimeRemaining = 0;

// ==================== NOTIFICATION SYSTEM ====================
function showNotification(data) {
    const container = document.getElementById('notification-container');
    
    const notification = document.createElement('div');
    notification.className = `notification ${data.type || 'info'}`;
    
    const duration = data.duration || 5000;
    
    notification.innerHTML = `
        <div class="notification-icon">
            <i class="fas fa-${data.icon || 'info-circle'}"></i>
        </div>
        <div class="notification-content">
            <div class="notification-title">${data.title || 'Notice'}</div>
            <div class="notification-description">${data.description || ''}</div>
        </div>
        <div class="notification-progress" style="animation-duration: ${duration}ms;"></div>
    `;
    
    container.appendChild(notification);
    
    setTimeout(() => {
        notification.classList.add('hiding');
        setTimeout(() => {
            if (notification.parentNode) {
                notification.remove();
            }
        }, 300);
    }, duration);
}

// ==================== SERMON DISPLAY SYSTEM ====================
function showSermon(data) {
    const sermonDisplay = document.getElementById('sermon-display');
    const priestName = document.getElementById('sermon-priest-name');
    const sermonText = document.getElementById('sermon-text');
    const sermonTextWrapper = document.getElementById('sermon-text-wrapper');
    const timerText = document.getElementById('sermon-timer-text');
    const progressFill = document.getElementById('sermon-progress');
    const sermonContent = document.getElementById('sermon-content');
    
    // Set content
    priestName.textContent = data.priestName || 'A Priest';
    sermonText.textContent = data.message || '';
    
    // Calculate duration based on word count
    const wordCount = data.message ? data.message.split(/\s+/).length : 0;
    const calculatedDuration = Math.min(Math.max(45, Math.ceil(wordCount / 100) * 15 + 30), 180);
    sermonTimeRemaining = data.duration || calculatedDuration;
    
    // Set CSS variables for animations
    if (progressFill) {
        progressFill.style.animation = 'none';
        progressFill.offsetHeight; // Trigger reflow
        progressFill.style.animation = `progressShrink ${sermonTimeRemaining}s linear forwards`;
    }
    
    // Calculate scroll distance for auto-scroll
    setTimeout(() => {
        if (sermonContent && sermonTextWrapper) {
            const contentHeight = sermonContent.clientHeight;
            const textHeight = sermonTextWrapper.scrollHeight;
            const scrollDistance = Math.max(0, textHeight - contentHeight + 50);
            
            if (scrollDistance > 0) {
                const scrollDuration = sermonTimeRemaining - 5;
                sermonTextWrapper.style.setProperty('--scroll-distance', `-${scrollDistance}px`);
                sermonTextWrapper.style.setProperty('--scroll-duration', `${scrollDuration}s`);
                sermonTextWrapper.style.animation = 'none';
                sermonTextWrapper.offsetHeight;
                sermonTextWrapper.style.animation = `autoScroll ${scrollDuration}s linear forwards`;
                sermonTextWrapper.style.animationDelay = '3s';
            } else {
                sermonTextWrapper.style.animation = 'none';
            }
        }
    }, 100);
    
    // Clear any existing timer
    if (sermonTimer) {
        clearInterval(sermonTimer);
        sermonTimer = null;
    }
    
    // Update timer display
    if (timerText) {
        timerText.textContent = `${sermonTimeRemaining}s remaining`;
    }
    
    // Start countdown timer
    sermonTimer = setInterval(() => {
        sermonTimeRemaining--;
        if (timerText) {
            timerText.textContent = `${sermonTimeRemaining}s remaining`;
        }
        
        if (sermonTimeRemaining <= 0) {
            hideSermon();
        }
    }, 1000);
    
    // Show the sermon
    sermonDisplay.classList.remove('hidden');
    sermonDisplay.classList.remove('hiding');
    
    // Reset text wrapper position
    if (sermonTextWrapper) {
        sermonTextWrapper.style.transform = 'translateY(0)';
    }
    
    console.log('[Sermon] Showing sermon from ' + data.priestName + ' for ' + sermonTimeRemaining + 's');
}

function hideSermon() {
    const sermonDisplay = document.getElementById('sermon-display');
    const sermonTextWrapper = document.getElementById('sermon-text-wrapper');
    
    // Clear timer
    if (sermonTimer) {
        clearInterval(sermonTimer);
        sermonTimer = null;
    }
    
    // Stop animations
    if (sermonTextWrapper) {
        sermonTextWrapper.style.animation = 'none';
    }
    
    // Animate out
    if (sermonDisplay) {
        sermonDisplay.classList.add('hiding');
        
        setTimeout(() => {
            sermonDisplay.classList.add('hidden');
            sermonDisplay.classList.remove('hiding');
        }, 400);
    }
    
    console.log('[Sermon] Hidden');
}

// ==================== MENU SYSTEM ====================
function showMenu(data) {
    const menu = document.getElementById('bible-menu');
    const optionsContainer = document.getElementById('menu-options');
    const menuTitle = document.getElementById('menu-title');
    const sermonDisplay = document.getElementById('sermon-display');
    
    currentMenuType = data.type || 'main';
    currentMenuData = data;
    
    // Dim sermon if visible
    if (sermonDisplay && !sermonDisplay.classList.contains('hidden')) {
        sermonDisplay.classList.add('has-menu');
    }
    
    if (menuTitle) {
        menuTitle.textContent = data.title || 'Sacred Actions';
    }
    
    if (optionsContainer) {
        optionsContainer.innerHTML = '';
        
        if (data.options && Array.isArray(data.options)) {
            data.options.forEach((option, index) => {
                const optionElement = document.createElement('div');
                optionElement.className = 'menu-option';
                
                if (option.isBack) optionElement.classList.add('back-btn');
                if (option.isStopHymn) optionElement.classList.add('stop-hymn');
                
                let iconStyle = '';
                if (option.iconColor) {
                    iconStyle = `style="background: ${option.iconColor}; color: #fff;"`;
                }
                
                optionElement.innerHTML = `
                    <div class="menu-option-icon" ${iconStyle}>
                        <i class="fas fa-${option.icon || 'circle'}"></i>
                    </div>
                    <div class="menu-option-content">
                        <div class="menu-option-title">${option.title || ''}</div>
                        <div class="menu-option-description">${option.description || ''}</div>
                    </div>
                    <div class="menu-option-arrow">
                        <i class="fas fa-chevron-right"></i>
                    </div>
                `;
                
                optionElement.addEventListener('click', () => {
                    optionElement.style.transform = 'scale(0.98)';
                    setTimeout(() => {
                        optionElement.style.transform = '';
                    }, 100);
                    
                    fetch(`https://${getResourceName()}/menuSelect`, {
                        method: 'POST',
                        headers: { 'Content-Type': 'application/json' },
                        body: JSON.stringify({
                            action: option.action || '',
                            index: index,
                            data: option.data || null
                        })
                    }).catch(err => console.log('Fetch error:', err));
                });
                
                optionsContainer.appendChild(optionElement);
            });
        }
    }
    
    if (menu) {
        menu.classList.remove('hidden');
    }
}

function hideMenu() {
    const menu = document.getElementById('bible-menu');
    const sermonDisplay = document.getElementById('sermon-display');
    
    if (menu) {
        menu.classList.add('hidden');
    }
    
    currentMenuType = 'main';
    currentMenuData = null;
    
    // Restore sermon visibility
    if (sermonDisplay) {
        sermonDisplay.classList.remove('has-menu');
    }
}

// ==================== INPUT DIALOG ====================
function showInputDialog(data) {
    const dialog = document.getElementById('input-dialog');
    const dialogTitle = document.getElementById('dialog-title');
    const dialogInputs = document.getElementById('dialog-inputs');
    
    if (dialogTitle) {
        dialogTitle.textContent = data.title || 'Enter Information';
    }
    
    if (dialogInputs) {
        dialogInputs.innerHTML = '';
        
        if (data.inputs && Array.isArray(data.inputs)) {
            data.inputs.forEach((input, index) => {
                const inputGroup = document.createElement('div');
                inputGroup.className = 'input-group';
                
                let inputElement = '';
                if (input.type === 'textarea') {
                    inputElement = `
                        <textarea 
                            id="dialog-input-${index}" 
                            placeholder="${input.placeholder || ''}"
                            ${input.required ? 'required' : ''}
                            minlength="${input.min || 0}"
                            maxlength="${input.max || 1000}"
                        ></textarea>
                    `;
                } else {
                    inputElement = `
                        <input 
                            type="${input.type || 'text'}" 
                            id="dialog-input-${index}" 
                            placeholder="${input.placeholder || ''}"
                            ${input.required ? 'required' : ''}
                            minlength="${input.min || 0}"
                            maxlength="${input.max || 200}"
                        >
                    `;
                }
                
                inputGroup.innerHTML = `
                    <label for="dialog-input-${index}">${input.label || ''}</label>
                    ${input.description ? `<div class="input-description">${input.description}</div>` : ''}
                    ${inputElement}
                `;
                
                dialogInputs.appendChild(inputGroup);
            });
        }
    }
    
    inputCallback = data.callback || null;
    
    if (dialog) {
        dialog.classList.remove('hidden');
    }
    
    setTimeout(() => {
        if (dialogInputs) {
            const firstInput = dialogInputs.querySelector('input, textarea');
            if (firstInput) firstInput.focus();
        }
    }, 100);
}

function hideInputDialog() {
    const dialog = document.getElementById('input-dialog');
    if (dialog) {
        dialog.classList.add('hidden');
    }
    inputCallback = null;
}

function submitDialog() {
    const dialogInputs = document.getElementById('dialog-inputs');
    if (!dialogInputs) return;
    
    const inputs = dialogInputs.querySelectorAll('input, textarea');
    const values = [];
    
    let isValid = true;
    inputs.forEach(input => {
        if (input.required && !input.value.trim()) {
            isValid = false;
            input.parentElement.classList.add('shake');
            setTimeout(() => {
                input.parentElement.classList.remove('shake');
            }, 500);
        }
        values.push(input.value);
    });
    
    if (!isValid) {
        showNotification({
            title: 'Validation Error',
            description: 'Please fill in all required fields',
            type: 'error',
            icon: 'exclamation-triangle',
            duration: 3000
        });
        return;
    }
    
    fetch(`https://${getResourceName()}/inputSubmit`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ values: values })
    }).catch(err => console.log('Fetch error:', err));
    
    hideInputDialog();
}

// ==================== LOADING OVERLAY ====================
function showLoading(text) {
    const loading = document.getElementById('loading-overlay');
    if (loading) {
        const loadingText = loading.querySelector('.loading-text');
        if (loadingText) {
            loadingText.textContent = text || 'Loading...';
        }
        loading.classList.remove('hidden');
    }
}

function hideLoading() {
    const loading = document.getElementById('loading-overlay');
    if (loading) {
        loading.classList.add('hidden');
    }
}

// ==================== EVENT LISTENERS ====================
document.addEventListener('DOMContentLoaded', function() {
    // Cancel button
    const cancelBtn = document.getElementById('dialog-cancel');
    if (cancelBtn) {
        cancelBtn.addEventListener('click', () => {
            fetch(`https://${getResourceName()}/inputCancel`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({})
            }).catch(err => console.log('Fetch error:', err));
            hideInputDialog();
        });
    }
    
    // Confirm button
    const confirmBtn = document.getElementById('dialog-confirm');
    if (confirmBtn) {
        confirmBtn.addEventListener('click', submitDialog);
    }
    
    // Sermon close button (if it exists)
    const sermonCloseBtn = document.getElementById('sermon-close');
    if (sermonCloseBtn) {
        sermonCloseBtn.addEventListener('click', () => {
            hideSermon();
        });
    }
});

// Escape key handler
document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
        const inputDialog = document.getElementById('input-dialog');
        const bibleMenu = document.getElementById('bible-menu');
        const sermonDisplay = document.getElementById('sermon-display');
        
        if (inputDialog && !inputDialog.classList.contains('hidden')) {
            fetch(`https://${getResourceName()}/inputCancel`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({})
            }).catch(err => console.log('Fetch error:', err));
            hideInputDialog();
        } else if (bibleMenu && !bibleMenu.classList.contains('hidden')) {
            fetch(`https://${getResourceName()}/closeMenu`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({})
            }).catch(err => console.log('Fetch error:', err));
            hideMenu();
        } else if (sermonDisplay && !sermonDisplay.classList.contains('hidden')) {
            hideSermon();
        }
    }
    
    // Enter key for dialog submit
    if (e.key === 'Enter' && !e.shiftKey) {
        const inputDialog = document.getElementById('input-dialog');
        if (inputDialog && !inputDialog.classList.contains('hidden')) {
            const focusedElement = document.activeElement;
            if (focusedElement && focusedElement.tagName !== 'TEXTAREA') {
                submitDialog();
            }
        }
    }
});

// ==================== NUI MESSAGE HANDLER ====================
window.addEventListener('message', (event) => {
    const data = event.data;
    
    if (!data || !data.action) return;
    
    switch (data.action) {
        case 'showNotification':
            if (data.data) {
                showNotification(data.data);
            }
            break;
            
        case 'showMenu':
            if (data.data) {
                showMenu(data.data);
            }
            break;
            
        case 'hideMenu':
            hideMenu();
            break;
            
        case 'showInput':
            if (data.data) {
                showInputDialog(data.data);
            }
            break;
            
        case 'hideInput':
            hideInputDialog();
            break;
            
        case 'showLoading':
            showLoading(data.text);
            break;
            
        case 'hideLoading':
            hideLoading();
            break;
            
        case 'showSermon':
            if (data.data) {
                showSermon(data.data);
            }
            break;
            
        case 'hideSermon':
            hideSermon();
            break;
    }
});

console.log('[Priest Bible UI] Script loaded successfully');