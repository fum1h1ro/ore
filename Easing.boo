namespace ore
import UnityEngine

/*
   TERMS OF USE - EASING EQUATIONS
   ---------------------------------------------------------------------------------
   Open source under the BSD License.

   Copyright © 2001 Robert Penner All rights reserved.

   Redistribution and use in source and binary forms, with or without
   modification, are permitted provided that the following conditions are met:

   Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer. Redistributions in binary
   form must reproduce the above copyright notice, this list of conditions and
   the following disclaimer in the documentation and/or other materials provided
   with the distribution. Neither the name of the author nor the names of
   contributors may be used to endorse or promote products derived from this
   software without specific prior written permission.

   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
   AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
   IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
   DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
   FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
   DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
   SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
   CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
   OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
   OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
   ---------------------------------------------------------------------------------
 */

public static class Easing ():
  private final PI_M2 = Mathf.PI * 2.0f
  private final PI_D2 = Mathf.PI / 2.0f

  /*
     Linear
     ---------------------------------------------------------------------------------
   */
  public def easeLinear(t as single, b as single, c as single, d as single) as single:
    return c * t / d + b
  /*
     Sine
     ---------------------------------------------------------------------------------
   */
  public def easeInSine(t as single, b as single, c as single, d as single) as single:
    return -c * Mathf.Cos(t / d * PI_D2) + c + b
  public def easeOutSine(t as single, b as single, c as single, d as single) as single:
    return c * Mathf.Sin(t / d * PI_D2) + b
  public def easeInOutSine(t as single, b as single, c as single, d as single) as single:
    return -c / 2.0f * (Mathf.Cos(Mathf.PI * t / d) - 1.0f) + b
  /*
     Quintic
     ---------------------------------------------------------------------------------
   */
  public def easeInQuint(t as single, b as single, c as single, d as single) as single:
    return c * (t /= d) * t * t * t * t + b
  public def easeOutQuint(t as single, b as single, c as single, d as single) as single:
    return c *((t = t / d - 1.0f) * t * t * t * t + 1.0f) + b
  public def easeInOutQuint(t as single, b as single, c as single, d as single) as single:
    return c / 2 * t * t * t * t * t + b if (t /= d / 2) < 1.0f
    return c / 2 * ((t -= 2) * t * t * t * t + 2) + b
  /*
     Quartic
     ---------------------------------------------------------------------------------
   */
  public def easeInQuart (t as single, b as single, c as single, d as single) as single:
    return c * (t /= d) * t * t * t + b
  public def easeOutQuart (t as single, b as single, c as single, d as single) as single:
    return -c * ((t = t / d - 1.0f) * t * t * t - 1.0f) + b
  public def easeInOutQuart (t as single, b as single, c as single, d as single) as single:
    return c / 2 * t * t * t * t + b if (t /= d / 2) < 1.0f
    return -c / 2 * ((t -= 2) * t * t * t - 2) + b
  /*
     Quadratic
     ---------------------------------------------------------------------------------
   */
  public def easeInQuad (t as single, b as single, c as single, d as single) as single:
    return c * (t /= d) * t + b
  public def easeOutQuad (t as single, b as single, c as single, d as single) as single:
    return -c * (t /= d) * (t - 2) + b
  public def easeInOutQuad (t as single, b as single, c as single, d as single) as single:
    return c / 2 * t * t + b if (t /= d / 2) < 1.0f
    return -c / 2 * ((--t) * (t - 2) - 1.0f) + b
  /*
     Exponential
     ---------------------------------------------------------------------------------
   */
  public def easeInExpo (t as single, b as single, c as single, d as single) as single:
    return (b if t == 0 else c * Mathf.Pow(2, 10 * (t / d - 1.0f)) + b)
  public def easeOutExpo (t as single, b as single, c as single, d as single) as single:
    return (b + c if t == d else c * (-Mathf.Pow(2, -10 * t / d) + 1.0f) + b)
  public def easeInOutExpo (t as single, b as single, c as single, d as single) as single:
    return b if (t == 0)
    return b + c if (t == d)
    return c / 2 * Mathf.Pow(2, 10 * (t - 1.0f)) + b if ((t /= d / 2) < 1.0f)
    return c / 2 * (-Mathf.Pow(2, -10 * --t) + 2) + b

  /*
     Elastic
     ---------------------------------------------------------------------------------
   */
  /*
  public def easeInElastic (t as single, b as single, c as single, d as single, a as single=undefined, p as single=undefined) as single:
    s as single;
    return b if t==0
    return b+c if (t /= d)==1.0f
    p=d*.3 if not p
    if (!a || a < Mathf.abs(c)) { a=c; s=p/4; }
    else s = p/PI_M2 * Mathf.asin (c/a);
    return -(a*Mathf.Pow(2,10*(t-=1.0f)) * Mathf.sin( (t*d-s)*PI_M2/p )) + b;
  }
  public def easeOutElastic (t as single, b as single, c as single, d as single, a as single=undefined, p as single=undefined) as single:
  {
    var s as single;
    if (t==0) return b;  if ((t/=d)==1.0f) return b+c;  if (!p) p=d*.3;
    if (!a || a < Mathf.abs(c)) { a=c; s=p/4; }
    else s = p/PI_M2 * Mathf.asin (c/a);
    return (a*Mathf.Pow(2,-10*t) * Mathf.sin( (t*d-s)*PI_M2/p ) + c + b);
  }
  public def easeInOutElastic (t as single, b as single, c as single, d as single, a as single=undefined, p as single=undefined) as single:
  {
    var s as single;
    if (t==0) return b;  if ((t/=d/2)==2) return b+c;  if (!p) p=d*(.3*1.5);
    if (!a || a < Mathf.abs(c)) { a=c; s=p/4; }
    else s = p/PI_M2 * Mathf.asin (c/a);
    if (t < 1.0f) return -.5*(a*Mathf.Pow(2,10*(t-=1)) * Mathf.sin( (t*d-s)*PI_M2/p )) + b;
    return a*Mathf.Pow(2,-10*(t-=1.0f)) * Mathf.sin( (t*d-s)*PI_M2/p )*.5 + c + b;
  }
  */
  /*
     Circular
     ---------------------------------------------------------------------------------
   */
  public def easeInCircular(t as single, b as single, c as single, d as single) as single:
    return -c * (Mathf.Sqrt(1.0f - (t /= d) * t) - 1.0f) + b
  public def easeOutCircular(t as single, b as single, c as single, d as single) as single:
    return c * Mathf.Sqrt(1.0f - (t = t / d - 1.0f) * t) + b
  public def easeInOutCircular(t as single, b as single, c as single, d as single) as single:
    return -c / 2 * (Mathf.Sqrt(1.0f - t * t) - 1.0f) + b if (t /= d / 2) < 1.0f
    return c / 2 * (Mathf.Sqrt(1.0f - (t -= 2) * t) + 1.0f) + b

  /*
     Back
     ---------------------------------------------------------------------------------
   */
  public def easeInBack(t as single, b as single, c as single, d as single) as single:
    return easeInBack(t, b, c, d, 1.70158f)
  public def easeInBack(t as single, b as single, c as single, d as single, s as single) as single:
    return c * (t /= d) * t * ((s + 1) * t - s) + b
  public def easeOutBack(t as single, b as single, c as single, d as single) as single:
    return easeOutBack(t, b, c, d, 1.70158f)
  public def easeOutBack(t as single, b as single, c as single, d as single, s as single) as single:
    return c * ((t = t / d - 1.0f) * t * ((s + 1.0f) * t + s) + 1.0f) + b
  public def easeInOutBack(t as single, b as single, c as single, d as single) as single:
    return easeInOutBack(t, b, c, d, 1.70158f)
  public def easeInOutBack(t as single, b as single, c as single, d as single, s as single) as single:
    return c / 2 * ( t * t * (((s *= (1.525f)) + 1) * t - s)) + b if (t /= d / 2) < 1
    return c / 2 * ((t -= 2) * t * (((s *= (1.525f)) + 1) * t + s) + 2) + b
  /*
     Bounce
     ---------------------------------------------------------------------------------
   */
  public def easeInBounce(t as single, b as single, c as single, d as single) as single:
    return c - easeOutBounce(d - t, 0.0f, c, d) + b
  public def easeOutBounce(t as single, b as single, c as single, d as single) as single:
    if (t /= d) < (1.0f / 2.75f):
      return c * (7.5625f * t * t) + b
    elif t < (2.0f / 2.75f):
      return c * (7.5625f * (t -= (1.5f / 2.75f)) * t + 0.75f) + b
    elif t < (2.5f / 2.75f):
      return c * (7.5625f * (t -= (2.25f /2.75f)) * t + 0.9375f) + b
    else:
      return c * (7.5625f * (t -= (2.625f / 2.75f)) * t + 0.984375f) + b
  public def easeInOutBounce(t as single, b as single, c as single, d as single) as single:
    if t < d / 2.0f:
      return easeInBounce(t * 2.0f, 0.0f, c, d) * .5f + b
    else:
      return easeOutBounce(t * 2.0f - d, 0.0f, c, d) * .5f + c * .5f + b
  /*
     Cubic
     ---------------------------------------------------------------------------------
   */
  public def easeInCubic(t as single, b as single, c as single, d as single) as single:
    return c * (t /= d) * t * t + b
  public def easeOutCubic(t as single, b as single, c as single, d as single) as single:
    return c * ((t = t / d - 1) * t * t + 1) + b
  public def easeInOutCubic(t as single, b as single, c as single, d as single) as single:
    return c / 2.0f * t * t * t + b if (t /= d / 2.0f) < 1.0f
    return c / 2.0f * ((t -= 2.0f) * t * t + 2.0f) + b
