// Factory that returns the dialogue array for the new tutorial.
// Accepts displayName so the calling controller can inject runtime values.
function getNewTutorialDialogue(scene = "intro", params = {}) {
    if (scene === "intro") {
        return getNewTutorialIntroDialogue(params);
    } else if (scene === "ship") {
        return getNewTutorialShipDialogue(params);
    }
}

function getNewTutorialCheckpointStep(scene = "intro", checkpoint) {
  const dialogue = getNewTutorialDialogue(scene);
  const i = dialogue.findIndex(step => step.checkpoint === checkpoint);
  return i === -1 ? 0 : i;
}

function getNewTutorialIntroDialogue(params = {}) {
  const name = params.displayName ?? "Hey";

  return [
    // intro
    { text: `Psst! Hey there! <span class="new-tutorial-shake">${name}!</span>` },
    { text: `Welcome to the... <span class="new-tutorial-shake">SUMMER OF MAKING!!!</span>` },
    { text: `Oh... I don't believe I've introduced myself.<br>I'm Explorpheus!` },
    { text: `I'm here to guide you through everything you need to know to start shipping and earning <span class="new-tutorial-bling">prizes</span>` },

    // campfire
    {
      text: `You're currently at the Campfire! This is where the latest news is shared!`,
      focus: 'new-tutorial-campfire-title', x: 0, y: 10, width: 50, height: -50, radius: 20
    },
    {
      text: `You should check back here every once in a while! There's always so much happening on the island!`,
      focus: 'new-tutorial-campfire-title', x: 0, y: 10, width: 50, height: -50, radius: 20
    },

    // currency
    { text: `Shells are our currency here. You can get so much cool stuff with them, but to get 'em, you gotta...` },
    { text: `<span class="new-tutorial-shake">Build cool projects and ship them!</span>` },
    { text: `Awesome! Let's dive a bit deeper!` },
    {
      text: `Check out this video!`,
      video: '/onboarding.mp4', skip: 10
    },

    // step-by-step - skipped if watched video
    { text: `I'll walk you through what this is about!` },
    { text: `1. Come up with a cool project idea. Make it something you've always wanted to build.` },
    { text: `2. Start building! Track how much time you spent with Hackatime.` },
    { text: `3. As you build, post <span class="new-tutorial-shake">devlogs</span>! They're mini updates on your progress.` },
    { text: `4. Once it's ready, <span class="new-tutorial-shake">ship it</span> to the world! It doesn't have to be perfect. A MVP is okay!` },
    { text: `5. Our shipwrights will make sure your project is working. They'll give you feedback!` },
    { text: `6. Your project will then be voted on by the community. You'll vote on others' projects as well.` },
    { text: `7. You'll earn shells depending on the number of votes and how long you've worked on your project.` },
    { text: `8. You can spend these shells in our shop for awesome prizes!` },
    { text: `Alright, that was quite the ramble...` },

    // hackatime
    { text: `Don't worry if this is confusing, I'll walk you through each step` },
    { 
      text: `We use Hackatime to track your time spent. You'll need to get that set up.`,
      condition: 'hackatime',
      alt: {
        text: `We use Hackatime to track your time spent. You're all set up on Hackatime!`,
      },
      checkpoint: 'hackatime',
      skip: 1
    },
    {
      // skipped if hackatime is set up
      text: `Head to the Hackatime website. Follow the instructions there. I'll be waiting for you!`,
      focus: 'new-tutorial-hackatime', focusOther: ['new-tutorial-hackatime-container'], 
      x: 0, y: 0, width: 30, height: 30, radius: 10, preventAdvance: true
    },
    {
      text: "Let's create your first project",
      checkpoint: 'hackatime-installed'
    }
  ];
}

function getNewTutorialShipDialogue(params = {}) {

}