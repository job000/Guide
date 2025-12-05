/**
 * Copy Code Button - Automatisk kopieringsknapp for kodeblokker
 * Legger til "Kopier" knapp på alle <pre> elementer
 */

document.addEventListener('DOMContentLoaded', function() {
  // Finn alle pre-elementer som ikke allerede er i en code-block wrapper
  const preElements = document.querySelectorAll('pre');

  preElements.forEach(function(pre) {
    // Hopp over hvis allerede wrapped
    if (pre.parentElement.classList.contains('code-block')) {
      addCopyButton(pre.parentElement, pre);
      return;
    }

    // Opprett wrapper
    const wrapper = document.createElement('div');
    wrapper.className = 'code-block';

    // Sett inn wrapper før pre
    pre.parentNode.insertBefore(wrapper, pre);

    // Flytt pre inn i wrapper
    wrapper.appendChild(pre);

    // Legg til kopieringsknapp
    addCopyButton(wrapper, pre);
  });
});

function addCopyButton(wrapper, pre) {
  // Sjekk om knapp allerede finnes
  if (wrapper.querySelector('.copy-btn')) return;

  const button = document.createElement('button');
  button.className = 'copy-btn';
  button.innerHTML = `
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
      <rect x="9" y="9" width="13" height="13" rx="2" ry="2"></rect>
      <path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"></path>
    </svg>
    <span>Kopier</span>
  `;

  button.addEventListener('click', function() {
    const code = pre.querySelector('code') || pre;
    const text = code.textContent;

    navigator.clipboard.writeText(text).then(function() {
      // Vis suksess
      button.classList.add('copied');
      button.innerHTML = `
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <polyline points="20 6 9 17 4 12"></polyline>
        </svg>
        <span>Kopiert!</span>
      `;

      // Tilbakestill etter 2 sekunder
      setTimeout(function() {
        button.classList.remove('copied');
        button.innerHTML = `
          <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <rect x="9" y="9" width="13" height="13" rx="2" ry="2"></rect>
            <path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"></path>
          </svg>
          <span>Kopier</span>
        `;
      }, 2000);
    }).catch(function(err) {
      console.error('Kunne ikke kopiere:', err);
      button.innerHTML = `
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <circle cx="12" cy="12" r="10"></circle>
          <line x1="15" y1="9" x2="9" y2="15"></line>
          <line x1="9" y1="9" x2="15" y2="15"></line>
        </svg>
        <span>Feil</span>
      `;
    });
  });

  wrapper.insertBefore(button, pre);
}
