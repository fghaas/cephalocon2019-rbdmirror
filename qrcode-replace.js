/* Grab all links and iterate over them */
document.querySelectorAll('a[href]').forEach(function(a) {
  /* Find an element named #qrcode-id, and render the QR code there */
  document.querySelectorAll('#qrcode-' + a.id).forEach(function(target) {
    var qr = new QRCode(target, {
        width : 500,
        height : 500,
        colorDark : "#000000",
        colorLight : "rgba(255,255,255,0)",
    });
    qr.makeCode(a.href);
  });
});
