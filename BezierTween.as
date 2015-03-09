package com.theintern.beziertween {
	import starling.animation.Tween;

	import flash.geom.Point;

	/**
	 * @author Leila Svantro
	 * Stardoll AB
	 */
	public class BezierTween extends Tween {
		public static const ACCURACY_FINE : Number = 0.001; // smoother curve animation
		public static const ACCURACY_COARSE : Number = 0.1; // less smooth curve animation
		public static const SPEED_DEFAULT : int = 0; // uneven speed throughout the curve
		public static const SPEED_EVEN : int = 1; // even speed throughout the curve
		
		private var mOnUpdate : Function;
		private var mOnUpdateArgs : Array;
		private var mAnchorPoints : Vector.<Point>;
		private var mBezierCurvePoints : Vector.<Point>;
		private var mCurveDistancesPercent : Vector.<Number>;
		private var mTarget : Object;

		public function BezierTween(target : Object, time : Number, anchorPoints : Vector.<Point>, speed : int = SPEED_DEFAULT, accuracy : Number = ACCURACY_FINE, transition : Object = "linear") {
			super(target, time, transition);

			this.mTarget = target;
			this.mAnchorPoints = anchorPoints;

			var amountCurvePoints : int;

			if (speed == SPEED_DEFAULT) {
				// calculate amount of points in the Bezier curve
				var calculationMiddleStep : Number = 1.0 / accuracy;
				if (calculationMiddleStep == Math.round(calculationMiddleStep)) {
					amountCurvePoints = calculationMiddleStep + 1;
				} else {
					amountCurvePoints = calculationMiddleStep + 2;
				}
				super.onUpdate = onUpdateDefault;
			} else if (speed == SPEED_EVEN) {
				mBezierCurvePoints = calculateBezierCurvePoints(accuracy);
				amountCurvePoints = mBezierCurvePoints.length;
				calculateEvenSpeed(amountCurvePoints);
				super.onUpdate = onUpdateEven;
			}
		}

		override public function get onUpdate() : Function {
			return mOnUpdate;
		}

		override public function get onUpdateArgs() : Array {
			return mOnUpdateArgs;
		}

		override public function set onUpdate(value : Function) : void {
			mOnUpdate = value;
		}

		override public function set onUpdateArgs(value : Array) : void {
			mOnUpdateArgs = value;
		}

		///////////////////////////////////////////////////////////////////////////////////////////////////
		
		private function onUpdateDefault() : void {
			var t : Number = this.progress;
			var point : Point = singleBezierPoint(t);
			mTarget["x"] = point.x;
			mTarget["y"] = point.y;

			// enables parent's custom update to be run
			if ( mOnUpdate != null ) {
				if ( mOnUpdateArgs != null ) {
					mOnUpdate.apply(null, mOnUpdateArgs);
				} else {
					mOnUpdate.apply(this, null);
				}
			}
		}

		private function onUpdateEven() : void {
			var t : Number = this.progress;

			if (t == 0 || t == 1) {
				onUpdateDefault();
				return;
			}

			for (var i : int = 0; i < mCurveDistancesPercent.length; i++) {
				if (t >= mCurveDistancesPercent[i] && t < mCurveDistancesPercent[i + 1]) {
					var a : Point = mBezierCurvePoints[i];
					var b : Point = mBezierCurvePoints[i + 1];
					var v : Number = t - mCurveDistancesPercent[i];
					var dT : Number = v / (mCurveDistancesPercent[i + 1] - mCurveDistancesPercent[i]);

					mTarget["x"] = a.x + (b.x - a.x) * dT;
					mTarget["y"] = a.y + (b.y - a.y) * dT;
				}
			}
			
			// enables parent's custom update to be run
			if ( mOnUpdate != null ) {
				if ( mOnUpdateArgs != null ) {
					mOnUpdate.apply(null, mOnUpdateArgs);
				} else {
					mOnUpdate.apply(this, null);
				}
			}
		}
		
		private function calculateEvenSpeed(amountCurvePoints : int) : void {
			mCurveDistancesPercent = new Vector.<Number>();

			var i : int;
			var percent : Number = 0;
			var distance : Number = 0;
			var totalDistance : Number = 0;
			var totalPercentToPoint : Number = 0;
			var curveDistances : Vector.<Number> = new Vector.<Number>();

			for (i = 0; i < amountCurvePoints - 1; i++) {
				distance = pythagoreanTheorem(mBezierCurvePoints[i], mBezierCurvePoints[i + 1]);
				totalDistance += distance;
				curveDistances.push(distance);
			}

			mCurveDistancesPercent.push(0);

			for (i = 0; i < curveDistances.length; i++) {
				percent = curveDistances[i] / totalDistance;
				totalPercentToPoint += percent;
				mCurveDistancesPercent.push(totalPercentToPoint);
			}
		}

		private function singleBezierPoint(t : Number) : Point {
			var n : Number = mAnchorPoints.length - 1;
			var x : Number = 0;
			var y : Number = 0;

			for (var i : int = 0; i <= n; i++) {
				x += binomialCoefficient(n, i) * Math.pow((1 - t), n - i) * Math.pow(t, i) * mAnchorPoints[i].x;
				y += binomialCoefficient(n, i) * Math.pow((1 - t), n - i) * Math.pow(t, i) * mAnchorPoints[i].y;
			}

			return new Point(x, y);
		}

		private function calculateBezierCurvePoints(accuracy : Number) : Vector.<Point> {
			var curvePoints : Vector.<Point> = new Vector.<Point>();
			var n : Number = mAnchorPoints.length - 1;
			var x : Number = 0;
			var y : Number = 0;

			// start point
			curvePoints.push(mAnchorPoints[0]);

			// curve points
			for (var t : Number = accuracy; t < 1.0; t = t + accuracy) {
				x = y = 0;
				for (var i : int = 0; i < n + 1; i++) {
					x += binomialCoefficient(n, i) * Math.pow((1 - t), n - i) * Math.pow(t, i) * mAnchorPoints[i].x;
					y += binomialCoefficient(n, i) * Math.pow((1 - t), n - i) * Math.pow(t, i) * mAnchorPoints[i].y;
				}
				curvePoints.push(new Point(x, y));
			}

			// end point
			curvePoints.push(mAnchorPoints[mAnchorPoints.length - 1]);

			return curvePoints;
		}

		private static function factorial(n : int) : int {
			/* Factorial: 
			 * n!
			 */
			var result : int = 1;

			if (n != 0) {
				for (var i : int = 1; i < n + 1; i++) {
					result *= i;
				}
			} else {
				return 1;
			}

			return result;
		}

		private static function binomialCoefficient(n : int, k : int) : int {
			/* Binomial coefficient:
			 *     n!
			 * ---------
			 * k! (n-k)!
			 */
			return factorial(n) / (factorial(k) * factorial(n - k));
		}

		private static function pythagoreanTheorem(a : Point, b : Point) : Number {
			/* Pythagorean theorem:
			 * a^2 + b^2 = c^2
			 */
			var dx : Number = b.x - a.x;
			var dy : Number = b.y - a.y;

			return Math.sqrt((dx * dx) + (dy * dy));
		}
	}
}
