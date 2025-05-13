#!/bin/sh

export PREFIX=/opt/toolflows
export PATH=$PATH:$PREFIX/bin

echo cloning sources.

cd src

git clone https://github.com/google/or-tools.git
git clone https://github.com/The-OpenROAD-Project/cudd.git
cd ..

git clone --recursive https://github.com/The-OpenROAD-Project/OpenROAD.git
cd OpenROAD
git checkout --recurse-submodules 834b7a0fb6de03c8e584256af2ecb7889b568343
#6b5937db431d2fa1023d3865f21ccd9b65781492
patch -p1 << 'EOF'
diff --git a/src/cts/src/HTreeBuilder.cpp b/src/cts/src/HTreeBuilder.cpp
index efb8081f2..6f57fd910 100644
--- a/src/cts/src/HTreeBuilder.cpp
+++ b/src/cts/src/HTreeBuilder.cpp
@@ -324,7 +324,7 @@ void HTreeBuilder::initSinkRegion()
   if (topLevelSinks.size() <= min_clustering_sinks_
       || !(options_->getSinkClustering())) {
     Box<int> sinkRegionDbu = clock_.computeSinkRegion();
-    logger_->info(CTS, 23, " Original sink region: {}.", sinkRegionDbu);
+//    logger_->info(CTS, 23, " Original sink region: {}.", sinkRegionDbu);
 
     sinkRegion_ = sinkRegionDbu.normalize(1.0 / wireSegmentUnit_);
   } else {
@@ -341,9 +341,9 @@ void HTreeBuilder::initSinkRegion()
     }
     sinkRegion_ = clock_.computeSinkRegionClustered(topLevelSinksClustered_);
   }
-  logger_->info(CTS, 24, " Normalized sink region: {}.", sinkRegion_);
-  logger_->info(CTS, 25, "    Width:  {:.4f}.", sinkRegion_.getWidth());
-  logger_->info(CTS, 26, "    Height: {:.4f}.", sinkRegion_.getHeight());
+//  logger_->info(CTS, 24, " Normalized sink region: {}.", sinkRegion_);
+//  logger_->info(CTS, 25, "    Width:  {:.4f}.", sinkRegion_.getWidth());
+//  logger_->info(CTS, 26, "    Height: {:.4f}.", sinkRegion_.getHeight());
 }
 
 void plotBlockage(std::ofstream& file, odb::dbDatabase* db_, int scalingFactor)
@@ -492,7 +492,8 @@ void HTreeBuilder::findLegalLocations(const Point<double>& parentPoint,
   addCandidateLoc((y1 - by) / m + bx, y1, parentPoint, x1, y1, x2, y2, points);
   addCandidateLoc((y2 - by) / m + bx, y2, parentPoint, x1, y1, x2, y2, points);
   // clang-format off
-  if (logger_->debugCheck(utl::CTS, "legalizer", 3)) {
+#if 0
+ if (logger_->debugCheck(utl::CTS, "legalizer", 3)) {
     logger_->report("    branchPt:{} is not legal, parentPt:{} blockages:({:0.3f} {:0.3f}) "
         "({:0.3f} {:0.3f})", branchPoint, parentPoint, x1, y1, x2, y2);
     for (Point<double> point : points) {
@@ -500,6 +501,7 @@ void HTreeBuilder::findLegalLocations(const Point<double>& parentPoint,
     }
     // clang-format on
   }
+#endif
 }
 
 Point<double> HTreeBuilder::findBestLegalLocation(
@@ -519,6 +521,7 @@ Point<double> HTreeBuilder::findBestLegalLocation(
   for (const Point<double>& loc : legalLocations) {
     double dist = computeDist(loc, parentPoint);
     double diff = abs(dist - targetDist);
+#if 0
     // clang-format off
     if (logger_->debugCheck(utl::CTS, "legalizer", 3)) {
       logger_->report("      Loc {}: curr dist={:0.3f} target dist={:0.3f} sink"
@@ -526,6 +529,7 @@ Point<double> HTreeBuilder::findBestLegalLocation(
 		      weightedDistance(loc, branchPoint, sinks));
     }
     // clang-format on
+#endif
     if (diff < minDiff) {
       minDiff = diff;
       best = loc;
@@ -589,11 +593,13 @@ bool HTreeBuilder::adjustAlongBlockage(double targetDist,
                                        Point<double>& bestLoc)
 {
   Point<double> newLoc = currLoc;
+#if 0
   // clang-format off
   debugPrint(logger_, CTS, "legalizer", 3, "{} currDist={:0.3f} != "
 	     "targetDist={:0.3f}, adjustAlongBlockage...", currLoc,
 	     computeDist(currLoc, parentPoint), targetDist);
   // clang-format on
+#endif
   double x = currLoc.getX();
   double y = currLoc.getY();
   double px = parentPoint.getX();
@@ -669,17 +675,21 @@ void HTreeBuilder::checkLegalityAndCostSpecial(
       bestLoc = newLoc;
       bestSinkDist = sinkDist;
     }
+#if 0
     // clang-format off
     debugPrint(logger_, CTS, "legalizer", 3, "adjustBestLegalLoc: branchPt "
 	       "move:{}=>{} is legal, dist={:0.3f}, sinkDist={:0.3f}",
 	       oldLoc, newLoc, targetDist, sinkDist);
     // clang-format on
+#endif
   }
+#if 0
   // clang-format off
   debugPrint(logger_, CTS, "legalizer", 3, "adjustBestLegalLoc: branchPt "
 	     "move:{}=>{} is illegal or dist {:0.3f} != {:0.3f}",
 	     oldLoc, newLoc, computeDist(newLoc, parentPoint), targetDist);
   // clang-format on
+#endif
 }
 
 // 1) Branch point couldn't be legalized by simply moving it along blockage
@@ -855,11 +865,13 @@ void HTreeBuilder::addCandidatePointsAlongBlockage(
     Point<double> point2 = point;
     double px = parentPoint.getX();
     double py = parentPoint.getY();
+#if 0
     // clang-format off
     debugPrint(logger_, CTS, "legalizer", 3, "  {} corner {} of Manhattan "
 	       "sqaure is inside blockage ({:0.3f} {:0.3f}) ({:0.3f} {:0.3f})",
 	       direction, point, x1, y1, x2, y2);
     // clang-format on
+#endif
     switch (direction) {
       case odb::Direction2D::North:
         //        ----------
@@ -932,13 +944,13 @@ void HTreeBuilder::checkLegalityAndCost(const Point<double>& oldLoc,
       bestSinkDist = sinkDist;
     }
     // clang-format off
-    debugPrint(logger_, CTS, "legalizer", 3, "adjustBeyondBlockage: branchPt "
-	       "move:{}=>{} is legal, dist={:0.3f}, sinkDist={:0.3f}",
-	       oldLoc, newLoc, targetDist, sinkDist);
-  } else {
-    debugPrint(logger_, CTS, "legalizer", 3, "adjustBeyondBlockage: branchPt "
-	       "move:{}=>{} is illegal or dist {:0.3f} != {:0.3f}",
-	       oldLoc, newLoc, computeDist(newLoc, parentPoint), targetDist);
+//    debugPrint(logger_, CTS, "legalizer", 3, "adjustBeyondBlockage: branchPt "
+//	       "move:{}=>{} is legal, dist={:0.3f}, sinkDist={:0.3f}",
+//	       oldLoc, newLoc, targetDist, sinkDist);
+//  } else {
+//    debugPrint(logger_, CTS, "legalizer", 3, "adjustBeyondBlockage: branchPt "
+//	       "move:{}=>{} is illegal or dist {:0.3f} != {:0.3f}",
+//	       oldLoc, newLoc, computeDist(newLoc, parentPoint), targetDist);
     // clang-format on
   }
 }
@@ -1000,11 +1012,13 @@ void HTreeBuilder::legalizeDummy()
                                                  scalingFactor);
         double d = computeDist(legalBranchPoint, parentPoint);
         // clang-format off
+#if 0
         debugPrint(logger_, CTS, "legalizer", 1,
             "legalizeDummy level index {}: {}->{} d={:0.3f}, leng={:0.3f},"
 		   "ratio={:0.3f}", levelIdx, branchPoint, legalBranchPoint,
 		   d, leng, d / leng);
         // clang-format on
+#endif
         commitMoveLoc(branchPoint, legalBranchPoint);
         branchPoint.setX(legalBranchPoint.getX());
         branchPoint.setY(legalBranchPoint.getY());
@@ -1026,8 +1040,8 @@ void HTreeBuilder::legalize()
   sinkRegion_.setCenter(newTopBufferLoc);
   commitMoveLoc(oldTopBufferLoc, newTopBufferLoc);
   // clang-format off
-  debugPrint(logger_, CTS, "legalizer", 3, "legalize: top buf loc:{}->{}",
-	     oldTopBufferLoc, newTopBufferLoc);
+//  debugPrint(logger_, CTS, "legalizer", 3, "legalize: top buf loc:{}->{}",
+//	     oldTopBufferLoc, newTopBufferLoc);
   // clang-format on
   for (int levelIdx = 0; levelIdx < topologyForEachLevel_.size(); ++levelIdx) {
     LevelTopology& topology = topologyForEachLevel_[levelIdx];
@@ -1048,6 +1062,7 @@ void HTreeBuilder::legalize()
           = topology.getBranchSinksLocations(bufferIdx);
 
       double leng = computeDist(branchPoint, parentPoint);
+#if 0
       // clang-format off
       if (logger_->debugCheck(utl::CTS, "legalizer", 3)) {
         logger_->report("  HTree level*{}* bufId*{}*, parent:{}, branch:{}, "
@@ -1055,6 +1070,7 @@ void HTreeBuilder::legalize()
 			parentPoint, branchPoint, leng, sinks.size());
       }
       // clang-format on
+#endif
       int scalingFactor = wireSegmentUnit_;
       double x1, y1, x2, y2;
       if (!isOccupiedLoc(branchPoint)
@@ -1075,6 +1091,7 @@ void HTreeBuilder::legalize()
                                                  x2,
                                                  y2,
                                                  scalingFactor);
+#if 0
         // clang-format off
 	debugPrint(logger_, CTS, "legalizer", 1,
 		   "findBestLegalLocation branchPt:{}=>{} parentPt:{} new "
@@ -1083,6 +1100,7 @@ void HTreeBuilder::legalize()
 		   isInsideBbox(legalBranchPoint.getX(), legalBranchPoint.getY(),
 				x1, y1, x2, y2)? "inside" : "outside");
         // clang-format on
+#endif
         // update branchPoint
         commitMoveLoc(branchPoint, legalBranchPoint);
         branchPoint = legalBranchPoint;
@@ -1096,12 +1114,14 @@ void HTreeBuilder::legalize()
                                            topology.getLength(),
                                            sinks,
                                            scalingFactor);
+#if 0
         // clang-format off
 	debugPrint(logger_, CTS, "legalizer", 3,
 		   "adjustBeyondBlockage applied to legal branchPt:{}=>{} "
 		   "parentPt:{} newDist={:0.3f}", branchPoint, newLocation,
 		   parentPoint, computeDist(newLocation, parentPoint));
         // clang-format on
+#endif
         commitMoveLoc(branchPoint, newLocation);
         branchPoint = newLocation;
       } else {
@@ -1203,10 +1223,10 @@ void HTreeBuilder::run()
   }
   createClockSubNets();
   // clang-format off
-  debugPrint(logger_, CTS, "legalizer", 3, "Htree file {} has been generated",
-             plotHTree());
-  debugPrint(logger_, CTS, "legalizer", 3, "Run 'obsAwareCts.py cts.clk.buffer'"
-	     "to produce cts.clk.buffer.png");
+//  debugPrint(logger_, CTS, "legalizer", 3, "Htree file {} has been generated",
+//             plotHTree());
+//  debugPrint(logger_, CTS, "legalizer", 3, "Run 'obsAwareCts.py cts.clk.buffer'"
+//	     "to produce cts.clk.buffer.png");
   // clang-format on
 }
 
@@ -1767,6 +1787,7 @@ void HTreeBuilder::createClockSubNets()
   ClockInst& rootBuffer = clock_.addClockBuffer(
       "clkbuf_0", options_->getRootBuffer(), centerX, centerY);
 
+#if 0
   // clang-format off
   if (center != legalCenter) {
     debugPrint(logger_, CTS, "legalizer", 2, "createClockSubNets: "
@@ -1776,6 +1797,7 @@ void HTreeBuilder::createClockSubNets()
 	       "root clkbuf_0: {}", center);
   }
   // clang-format on
+#endif
 
   addTreeLevelBuffer(&rootBuffer);
   ClockSubNet& rootClockSubNet = clock_.addSubNet("clknet_0");
@@ -1796,6 +1818,7 @@ void HTreeBuilder::createClockSubNets()
         = legalizeOneBuffer(branchPoint, options_->getRootBuffer());
     commitMoveLoc(branchPoint, legalBranchPoint);
 
+#if 0
     // clang-format off
     if (branchPoint != legalBranchPoint) {
       debugPrint(logger_, CTS, "legalizer", 2, 
@@ -1807,6 +1830,7 @@ void HTreeBuilder::createClockSubNets()
 		 std::to_string(idx), branchPoint);
     }
     // clang-format on
+#endif
 
     SegmentBuilder builder("clkbuf_1_" + std::to_string(idx) + "_",
                            "clknet_1_" + std::to_string(idx) + "_",
@@ -1853,6 +1877,7 @@ void HTreeBuilder::createClockSubNets()
           = legalizeOneBuffer(branchPoint, options_->getRootBuffer());
       commitMoveLoc(branchPoint, legalBranchPoint);
 
+#if 0
       // clang-format off
       if (branchPoint != legalBranchPoint) {
 	debugPrint(logger_, CTS, "legalizer", 2, "createClockSubNets level {} "
@@ -1866,6 +1891,7 @@ void HTreeBuilder::createClockSubNets()
 		   branchPoint);
       }
       // clang-format on
+#endif
 
       SegmentBuilder builder("clkbuf_" + std::to_string(levelIdx + 1) + "_"
                                  + std::to_string(idx) + "_",
@@ -1938,12 +1964,14 @@ void HTreeBuilder::createSingleBufferClockNet()
   ClockInst& rootBuffer = clock_.addClockBuffer(
       "clkbuf_0", options_->getRootBuffer(), centerX, centerY);
 
+#if 0
   // clang-format off
   if (center != legalCenter) {
     debugPrint(logger_, CTS, "legalizer", 2, "createSingleBufferClockNet "
 	       "legalizeOneBuffer clkbuf_0: {} => {}", center, legalCenter);
   }
   // clang-format on
+#endif
 
   addTreeLevelBuffer(&rootBuffer);
   ClockSubNet& clockSubNet = clock_.addSubNet("clknet_0");
@@ -2017,7 +2045,7 @@ void HTreeBuilder::plotSolution()
 void HTreeBuilder::printHTree()
 {
   Point<double> topLevelBufferLoc = sinkRegion_.getCenter();
-  logger_->report("HTree: top buf loc:{}", topLevelBufferLoc);
+//  logger_->report("HTree: top buf loc:{}", topLevelBufferLoc);
   for (int levelIdx = 0; levelIdx < topologyForEachLevel_.size(); ++levelIdx) {
     LevelTopology& topology = topologyForEachLevel_[levelIdx];
 
@@ -2035,6 +2063,7 @@ void HTreeBuilder::printHTree()
           = topology.getBranchSinksLocations(idx);
 
       double leng = topology.getLength();
+#if 0
       // clang-format off
       logger_->report("HTree: level*{}* bufId*{}*: branchPt:{} topo len:{:0.3f}"
 		      " dist to parent:{:0.3f} weighted sink len:{:0.3f} "
@@ -2043,6 +2072,7 @@ void HTreeBuilder::printHTree()
 		      weightedDistance(branchPoint, branchPoint, sinks),
 		      parentPoint);
       // clang-format on
+#endif
     }
     logger_->report("-------------------------------------------------");
   }
@@ -2115,6 +2145,7 @@ void SegmentBuilder::build(const std::string& forceBuffer)
       if (bufferLoc != legalBufferLoc) {
 	// adjust for cell movement
 	connectionLength -= tree_->computeDist(bufferLoc, legalBufferLoc);
+#if 0
 	debugPrint(getTree()->getLogger(), CTS, "legalizer", 2,
 		   " SegmentBuilder::build {} TCId:{} bufId:{} connLen:{:0.1f}: "
 		   "{} => {}", instPrefix_  + std::to_string(numBufferLevels_),
@@ -2125,6 +2156,7 @@ void SegmentBuilder::build(const std::string& forceBuffer)
 		   " SegmentBuilder::build {} TCId:{} bufId:{} connLen:{:0.1f}: "
 		   "{}", instPrefix_  + std::to_string(numBufferLevels_),
 		   techCharWireIdx, buffer, connectionLength, bufferLoc);
+#endif
       }
       // clang-format on
 
@@ -2154,8 +2186,8 @@ void SegmentBuilder::forceBufferInSegment(const std::string& master)
                                target_.getY() * techCharDistUnit_);
   tree_->addTreeLevelBuffer(&newBuffer);
   // clang-format off
-  debugPrint(getTree()->getLogger(), CTS, "legalizer", 2,
-	     "  forceBufferInSegment {}: {}", instPrefix_ + "_f", target_);
+//  debugPrint(getTree()->getLogger(), CTS, "legalizer", 2,
+//	     "  forceBufferInSegment {}: {}", instPrefix_ + "_f", target_);
   // clang-format on
 
   drivingSubNet_->addInst(newBuffer);
diff --git a/src/grt/src/fastroute/src/utility.cpp b/src/grt/src/fastroute/src/utility.cpp
index 66f48813c..43f614562 100644
--- a/src/grt/src/fastroute/src/utility.cpp
+++ b/src/grt/src/fastroute/src/utility.cpp
@@ -1690,6 +1690,7 @@ void FastRouteCore::printEdge2D(int netID, int edgeID)
   const TreeEdge edge = sttrees_[netID].edges[edgeID];
   const auto& nodes = sttrees_[netID].nodes;
 
+#if 0
   logger_->report("edge {}: n1 {} ({}, {})-> n2 {}({}, {}), routeType {}",
                   edgeID,
                   edge.n1,
@@ -1699,6 +1700,7 @@ void FastRouteCore::printEdge2D(int netID, int edgeID)
                   nodes[edge.n2].x,
                   nodes[edge.n2].y,
                   edge.route.type);
+#endif
   if (edge.len > 0) {
     std::string edge_rpt;
     for (int i = 0; i <= edge.route.routelen; i++) {
diff --git a/src/utl/include/utl/Logger.h b/src/utl/include/utl/Logger.h
index 280cb4554..4ee5817ea 100644
--- a/src/utl/include/utl/Logger.h
+++ b/src/utl/include/utl/Logger.h
@@ -128,12 +128,14 @@ class Logger
                     const Args&... args)
   {
     // Message counters do NOT apply to debug messages.
+#if 0 
     logger_->log(spdlog::level::level_enum::debug,
                  FMT_RUNTIME("[{} {}-{}] " + message),
                  level_names[spdlog::level::level_enum::debug],
                  tool_names_[tool],
                  group,
                  args...);
+#endif
     logger_->flush();
   }
 
@@ -163,7 +165,7 @@ class Logger
                                               const Args&... args)
   {
     error_count_++;
-    log(tool, spdlog::level::err, id, message, args...);
+//    log(tool, spdlog::level::err, id, message, args...);
     char tool_id[32];
     sprintf(tool_id, "%s-%04d", tool_names_[tool], id);
     std::runtime_error except(tool_id);
diff --git a/src/utl/src/timer.cpp b/src/utl/src/timer.cpp
index ef5a30b94..6347c1373 100644
--- a/src/utl/src/timer.cpp
+++ b/src/utl/src/timer.cpp
@@ -71,7 +71,7 @@ DebugScopedTimer::DebugScopedTimer(utl::Logger* logger,
 
 DebugScopedTimer::~DebugScopedTimer()
 {
-  debugPrint(logger_, tool_, group_.c_str(), level_, msg_, *this);
+  //debugPrint(logger_, tool_, group_.c_str(), level_, msg_, *this);
 }
 
 }  // namespace utl
EOF

cd ..

echo Building or-tools

mkdir build/or-tools
cd build/or-tools
cmake ../../src/or-tools -DBUILD_DEPS:BOOL=ON -DCMAKE_INSTALL_PREFIX=$PREFIX
make -j12
make install
cd ..

echo Building cudd 

git clone ../src/cudd
cd cudd
autoreconf
./configure --prefix=$PREFIX
make -j12
make install
cd ../..

echo Building OpenROAD for install to $PREFIX

cd OpenROAD
./etc/Build.sh -cmake="-DSPDLOG_FMT_EXTERNAL=OFF -DCMAKE_INSTALL_PREFIX=$PREFIX"

echo Install...
make -C build install

cd ..

echo Done.

