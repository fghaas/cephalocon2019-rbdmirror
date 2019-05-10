// Full list of configuration options available here:
// https://github.com/hakimel/reveal.js#configuration
Reveal.initialize({

    controls: false,

    progress: true,
    history: true,
    center: true,
    showNotes: false,


    transition: 'fade',

    totalTime: 40*60,

    multiplex: {
        secret: null,
        id: 'fbef2915cd793511',
        url: 'https://reveal-js-multiplex-ccjbegmaii.now.sh'
    },


    // Optional libraries used to extend on reveal.js
    dependencies: [
        { src: 'reveal.js/lib/js/classList.js', condition: function() { return !document.body.classList; } },
        { src: 'reveal.js/plugin/markdown/marked.js', condition: function() { return !!document.querySelector( '[data-markdown]' ); } },
        { src: 'reveal.js/plugin/markdown/markdown.js', condition: function() { return !!document.querySelector( '[data-markdown]' ); } },
        { src: 'reveal.js/plugin/highlight/highlight.js', async: true, callback: function() { hljs.initHighlightingOnLoad(); } },
        { src: 'reveal.js/plugin/zoom-js/zoom.js', async: true, condition: function() { return !!document.body.classList; } },
        { src: 'reveal.js/plugin/notes/notes.js', async: true, condition: function() { return !!document.body.classList; } },

        { src: '//cdn.socket.io/socket.io-1.3.5.js', async: true },

        { src: 'reveal.js/plugin/multiplex/client.js', async: true },

    ]
});
