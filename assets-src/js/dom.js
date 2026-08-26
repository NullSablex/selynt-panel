// Acesso ao elemento raiz do painel.
//
// Tudo do painel vive dentro de `.selynt-panel`; o resto da página é a skin do
// DirectAdmin, que não é nossa para tocar.

function getRoot() {
  return document.querySelector('.selynt-panel') || document.body;
}
export { getRoot };
