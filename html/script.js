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
let biblePages = [];
let flipbookInitialized = false;

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
            if (notification.parentNode) notification.remove();
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
    
    priestName.textContent = data.priestName || 'A Priest';
    sermonText.textContent = data.message || '';
    
    const wordCount = data.message ? data.message.split(/\s+/).length : 0;
    const calculatedDuration = Math.min(Math.max(45, Math.ceil(wordCount / 100) * 15 + 30), 180);
    sermonTimeRemaining = data.duration || calculatedDuration;
    
    if (progressFill) {
        progressFill.style.animation = 'none';
        progressFill.offsetHeight;
        progressFill.style.animation = `progressShrink ${sermonTimeRemaining}s linear forwards`;
    }
    
    setTimeout(() => {
        if (sermonContent && sermonTextWrapper) {
            const contentHeight = sermonContent.clientHeight;
            const textHeight = sermonTextWrapper.scrollHeight;
            const scrollDistance = Math.max(0, textHeight - contentHeight + 50);
            
            if (scrollDistance > 0) {
                const scrollDuration = sermonTimeRemaining - 5;
                sermonTextWrapper.style.setProperty('--scroll-distance', `-${scrollDistance}px`);
                sermonTextWrapper.style.animation = 'none';
                sermonTextWrapper.offsetHeight;
                sermonTextWrapper.style.animation = `autoScroll ${scrollDuration}s linear forwards`;
                sermonTextWrapper.style.animationDelay = '3s';
            } else {
                sermonTextWrapper.style.animation = 'none';
            }
        }
    }, 100);
    
    if (sermonTimer) {
        clearInterval(sermonTimer);
        sermonTimer = null;
    }
    
    if (timerText) timerText.textContent = `${sermonTimeRemaining}s remaining`;
    
    sermonTimer = setInterval(() => {
        sermonTimeRemaining--;
        if (timerText) timerText.textContent = `${sermonTimeRemaining}s remaining`;
        if (sermonTimeRemaining <= 0) hideSermon();
    }, 1000);
    
    sermonDisplay.classList.remove('hidden');
    sermonDisplay.classList.remove('hiding');
    if (sermonTextWrapper) sermonTextWrapper.style.transform = 'translateY(0)';
}

function hideSermon() {
    const sermonDisplay = document.getElementById('sermon-display');
    const sermonTextWrapper = document.getElementById('sermon-text-wrapper');
    
    if (sermonTimer) {
        clearInterval(sermonTimer);
        sermonTimer = null;
    }
    
    if (sermonTextWrapper) sermonTextWrapper.style.animation = 'none';
    
    if (sermonDisplay) {
        sermonDisplay.classList.add('hiding');
        setTimeout(() => {
            sermonDisplay.classList.add('hidden');
            sermonDisplay.classList.remove('hiding');
        }, 400);
    }
}

// ==================== BIBLE READER (TURN.JS) ====================

// How many words fit on one page (adjust based on font size)
const WORDS_PER_PAGE = 120;

// Split text into chunks that fit on a page
function splitTextIntoPages(text) {
    const words = text.split(' ');
    const pages = [];
    
    for (let i = 0; i < words.length; i += WORDS_PER_PAGE) {
        pages.push(words.slice(i, i + WORDS_PER_PAGE).join(' '));
    }
    
    return pages;
}

// Create page HTML
function createPageHTML(title, text, pageNum, isLeft, isContinuation) {
    const firstLetter = text.charAt(0);
    const restOfText = text.substring(1);
    
    const numClass = isLeft ? 'left-num' : 'right-num';
    const ornamentClass = isLeft ? 'left-ornament' : 'right-ornament';
    
    let html = `<div class="bible-page-content">`;
    
    if (title && !isContinuation) {
        html += `<div class="scripture-title">${title}</div>`;
    } else if (isContinuation && title) {
        html += `<div class="scripture-continuation">— ${title} (continued) —</div>`;
    }
    
    html += `<div class="scripture-text">`;
    
    // Only add drop cap on first page of each sermon (not continuations)
    if (!isContinuation) {
        html += `<span class="drop-cap">${firstLetter}</span>${restOfText}`;
    } else {
        html += text;
    }
    
    html += `</div></div>`;
    html += `<div class="page-num ${numClass}">${pageNum}</div>`;
    html += `<div class="page-ornament ${ornamentClass}">❧</div>`;
    
    return html;
}

function showBibleReader(data) {
    const reader = document.getElementById('bible-reader');
    const flipbook = document.getElementById('flipbook');
    
    biblePages = data.pages || [];
    
    // Clear existing pages
    flipbook.innerHTML = '';
    
    // Destroy existing turn.js instance
    if (flipbookInitialized) {
        try {
            $(flipbook).turn('destroy');
        } catch(e) {}
        flipbookInitialized = false;
    }
    
    // Create cover page
    const coverPage = document.createElement('div');
    coverPage.className = 'page hard';
    coverPage.innerHTML = `
        <div class="bible-cover-page">
            <div class="cover-corners corner-tl"></div>
            <div class="cover-corners corner-tr"></div>
            <div class="cover-corners corner-bl"></div>
            <div class="cover-corners corner-br"></div>
            <i class="fas fa-cross cover-cross"></i>
            <div class="cover-ornament-top"></div>
            <div class="cover-title">Holy Bible</div>
            <div class="cover-ornament-bottom"></div>
            <div class="cover-subtitle">The Sacred Scripture</div>
        </div>
    `;
    flipbook.appendChild(coverPage);
    
    // Create table of contents (inside cover)
    const tocPage = document.createElement('div');
    tocPage.className = 'page hard';
    tocPage.innerHTML = `
        <div class="bible-page-content" style="display:flex;flex-direction:column;align-items:center;justify-content:center;text-align:center;">
            <i class="fas fa-book-bible" style="font-size:50px;color:#8b4513;margin-bottom:20px;"></i>
            <div style="font-family:'Cinzel Decorative',serif;font-size:24px;color:#3d2b1f;margin-bottom:25px;">Table of Contents</div>
            <div style="font-family:'EB Garamond',serif;font-size:16px;color:#5d4037;text-align:left;line-height:2.2;columns:1;">
                ${biblePages.map((p, i) => `<div style="margin-bottom:5px;"><span style="color:#8b4513;font-weight:bold;">${i + 1}.</span> ${p.title}</div>`).join('')}
            </div>
        </div>
    `;
    flipbook.appendChild(tocPage);
    
    // Create content pages - split each sermon into multiple pages
    let pageNum = 1;
    
    biblePages.forEach((passage) => {
        // Split this sermon into page-sized chunks
        const textChunks = splitTextIntoPages(passage.content);
        
        textChunks.forEach((chunk, chunkIndex) => {
            const isFirstChunk = chunkIndex === 0;
            const isLeft = pageNum % 2 === 1;
            
            const contentPage = document.createElement('div');
            contentPage.className = 'page';
            contentPage.innerHTML = createPageHTML(
                passage.title, 
                chunk, 
                pageNum, 
                isLeft, 
                !isFirstChunk  // isContinuation
            );
            flipbook.appendChild(contentPage);
            pageNum++;
        });
    });
    
    // Ensure even number of pages (add blank if needed)
    const totalContentPages = flipbook.children.length;
    if (totalContentPages % 2 !== 0) {
        const blankPage = document.createElement('div');
        blankPage.className = 'page';
        blankPage.innerHTML = `
            <div class="bible-page-content" style="display:flex;align-items:center;justify-content:center;">
                <div style="color:#c9b896;font-size:40px;">❦</div>
            </div>
        `;
        flipbook.appendChild(blankPage);
    }
    
    // Back inside cover
    const insideBack = document.createElement('div');
    insideBack.className = 'page hard';
    insideBack.innerHTML = `
        <div class="bible-back-cover">
            <i class="fas fa-pray"></i>
            <div class="back-text">Amen</div>
        </div>
    `;
    flipbook.appendChild(insideBack);
    
    // Back cover
    const backCover = document.createElement('div');
    backCover.className = 'page hard';
    backCover.innerHTML = `
        <div class="bible-back-cover">
            <i class="fas fa-cross"></i>
            <div style="width:200px;height:2px;background:linear-gradient(90deg,transparent,#d4af37,transparent);margin:20px 0;"></div>
            <div class="back-text">Glory be to God</div>
        </div>
    `;
    flipbook.appendChild(backCover);
    
    // Show the reader
    reader.classList.remove('hidden');
    
    // Initialize turn.js
    setTimeout(() => {
        $(flipbook).turn({
            width: 1100,
            height: 700,
            autoCenter: true,
            display: 'double',
            acceleration: true,
            gradients: true,
            elevation: 50,
            duration: 1200,
            when: {
                turned: function(e, page) {
                    updatePageIndicator(page);
                }
            }
        });
        
        flipbookInitialized = true;
        updatePageIndicator(1);
        
        console.log('[Bible Reader] Turn.js initialized with ' + biblePages.length + ' passages');
    }, 100);
}

function updatePageIndicator(page) {
    const indicator = document.getElementById('page-indicator-text');
    const flipbook = document.getElementById('flipbook');
    
    if (indicator && flipbookInitialized) {
        try {
            const totalPages = $(flipbook).turn('pages');
            indicator.textContent = `Page ${page} of ${totalPages}`;
        } catch(e) {
            indicator.textContent = `Page ${page}`;
        }
    }
}

function hideBibleReader() {
    const reader = document.getElementById('bible-reader');
    const flipbook = document.getElementById('flipbook');
    
    if (flipbookInitialized) {
        try {
            $(flipbook).turn('destroy');
        } catch(e) {}
        flipbookInitialized = false;
    }
    
    reader.classList.add('hidden');
    
    fetch(`https://${getResourceName()}/closeBibleReader`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    }).catch(err => console.log('Fetch error:', err));
}

// ==================== MENU SYSTEM ====================
function showMenu(data) {
    const menu = document.getElementById('bible-menu');
    const optionsContainer = document.getElementById('menu-options');
    const menuTitle = document.getElementById('menu-title');
    
    currentMenuType = data.type || 'main';
    currentMenuData = data;
    
    if (menuTitle) menuTitle.textContent = data.title || 'Sacred Actions';
    
    if (optionsContainer) {
        optionsContainer.innerHTML = '';
        
        if (data.options && Array.isArray(data.options)) {
            data.options.forEach((option, index) => {
                const optionElement = document.createElement('div');
                optionElement.className = 'menu-option';
                
                if (option.isBack) optionElement.classList.add('back-btn');
                if (option.isStopHymn) optionElement.classList.add('stop-hymn');
                
                let iconStyle = '';
                if (option.iconColor) iconStyle = `style="background: ${option.iconColor}; color: #fff;"`;
                
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
                    setTimeout(() => { optionElement.style.transform = ''; }, 100);
                    
                    fetch(`https://${getResourceName()}/menuSelect`, {
                        method: 'POST',
                        headers: { 'Content-Type': 'application/json' },
                        body: JSON.stringify({ action: option.action || '', index: index, data: option.data || null })
                    }).catch(err => console.log('Fetch error:', err));
                });
                
                optionsContainer.appendChild(optionElement);
            });
        }
    }
    
    if (menu) menu.classList.remove('hidden');
}

function hideMenu() {
    const menu = document.getElementById('bible-menu');
    if (menu) menu.classList.add('hidden');
    currentMenuType = 'main';
    currentMenuData = null;
}

// ==================== INPUT DIALOG ====================
function showInputDialog(data) {
    const dialog = document.getElementById('input-dialog');
    const dialogTitle = document.getElementById('dialog-title');
    const dialogInputs = document.getElementById('dialog-inputs');
    
    if (dialogTitle) dialogTitle.textContent = data.title || 'Enter Information';
    
    if (dialogInputs) {
        dialogInputs.innerHTML = '';
        if (data.inputs && Array.isArray(data.inputs)) {
            data.inputs.forEach((input, index) => {
                const inputGroup = document.createElement('div');
                inputGroup.className = 'input-group';
                
                let el = '';
                if (input.type === 'textarea') {
                    el = `<textarea id="dialog-input-${index}" placeholder="${input.placeholder || ''}" ${input.required ? 'required' : ''} minlength="${input.min || 0}" maxlength="${input.max || 1000}"></textarea>`;
                } else {
                    el = `<input type="${input.type || 'text'}" id="dialog-input-${index}" placeholder="${input.placeholder || ''}" ${input.required ? 'required' : ''} minlength="${input.min || 0}" maxlength="${input.max || 200}">`;
                }
                
                inputGroup.innerHTML = `
                    <label for="dialog-input-${index}">${input.label || ''}</label>
                    ${input.description ? `<div class="input-description">${input.description}</div>` : ''}
                    ${el}
                `;
                dialogInputs.appendChild(inputGroup);
            });
        }
    }
    
    inputCallback = data.callback || null;
    if (dialog) dialog.classList.remove('hidden');
    
    setTimeout(() => {
        if (dialogInputs) {
            const firstInput = dialogInputs.querySelector('input, textarea');
            if (firstInput) firstInput.focus();
        }
    }, 100);
}

function hideInputDialog() {
    const dialog = document.getElementById('input-dialog');
    if (dialog) dialog.classList.add('hidden');
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
            setTimeout(() => { input.parentElement.classList.remove('shake'); }, 500);
        }
        values.push(input.value);
    });
    
    if (!isValid) {
        showNotification({ title: 'Error', description: 'Please fill in all fields', type: 'error', icon: 'exclamation-triangle', duration: 3000 });
        return;
    }
    
    fetch(`https://${getResourceName()}/inputSubmit`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ values: values })
    }).catch(err => console.log('Fetch error:', err));
    
    hideInputDialog();
}

// ==================== LOADING ====================
function showLoading(text) {
    const loading = document.getElementById('loading-overlay');
    if (loading) {
        const lt = loading.querySelector('.loading-text');
        if (lt) lt.textContent = text || 'Loading...';
        loading.classList.remove('hidden');
    }
}

function hideLoading() {
    const loading = document.getElementById('loading-overlay');
    if (loading) loading.classList.add('hidden');
}

// ==================== EVENT LISTENERS ====================
document.addEventListener('DOMContentLoaded', function() {
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
    
    const confirmBtn = document.getElementById('dialog-confirm');
    if (confirmBtn) confirmBtn.addEventListener('click', submitDialog);
});

// Keyboard handler - ESC only, no arrow keys
document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
        const inputDialog = document.getElementById('input-dialog');
        const bibleMenu = document.getElementById('bible-menu');
        const sermonDisplay = document.getElementById('sermon-display');
        const bibleReader = document.getElementById('bible-reader');
        
        if (inputDialog && !inputDialog.classList.contains('hidden')) {
            fetch(`https://${getResourceName()}/inputCancel`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({})
            }).catch(err => console.log('Fetch error:', err));
            hideInputDialog();
        } else if (bibleReader && !bibleReader.classList.contains('hidden')) {
            hideBibleReader();
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
            const focused = document.activeElement;
            if (focused && focused.tagName !== 'TEXTAREA') submitDialog();
        }
    }
});

// ==================== NUI MESSAGE HANDLER ====================
window.addEventListener('message', (event) => {
    const data = event.data;
    if (!data || !data.action) return;
    
    switch (data.action) {
        case 'showNotification': if (data.data) showNotification(data.data); break;
        case 'showMenu': if (data.data) showMenu(data.data); break;
        case 'hideMenu': hideMenu(); break;
        case 'showInput': if (data.data) showInputDialog(data.data); break;
        case 'hideInput': hideInputDialog(); break;
        case 'showLoading': showLoading(data.text); break;
        case 'hideLoading': hideLoading(); break;
        case 'showSermon': if (data.data) showSermon(data.data); break;
        case 'hideSermon': hideSermon(); break;
        case 'showBibleReader': if (data.data) showBibleReader(data.data); break;
        case 'hideBibleReader': hideBibleReader(); break;
    }
});

console.log('[Priest Bible UI] Script loaded with Turn.js - Mouse control only');