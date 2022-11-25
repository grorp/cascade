I first developed the sounds with this Javascript code:

```javascript
class Tx {
    constructor() {
        this.ctx = new AudioContext();
        this.time = 0;
    }

    tone(duration, frequency) {
        const oscillator = this.ctx.createOscillator();

        oscillator.type = 'square';
        oscillator.frequency.value = frequency;

        oscillator.connect(this.ctx.destination);
        oscillator.start(this.time);
        oscillator.stop(this.time + duration);

        this.time += duration;
    }

    break(duration) {
        this.time += duration;
    }
}
```

```javascript
// fail

const tx = new Tx();
tx.tone(0.15, 87.30705785825097); // F2
```

```javascript
// win

const tx = new Tx();
tx.tone(0.15, 698.4564628660078); // F5
tx.break(0.05);
tx.tone(0.75, 698.4564628660078); // F5
```

Then I recreated them in Audacity and amplified them by -18dB. Musical note frequencies from https://www.szynalski.com/tone-generator/.
