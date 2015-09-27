//
//  PKGeometricCoordinatizer.h
//  ProjectionKit
//
//  Copyright (c) 2015 Mustafa Youldash. All rights reserved.
//
//	Redistribution and use in source and binary forms, with or without
//	modification, are permitted provided that the following conditions are met:
//
//	* Redistributions of source code must retain the above copyright notice, this
//	list of conditions and the following disclaimer.
//
//	* Redistributions in binary form must reproduce the above copyright notice,
//	this list of conditions and the following disclaimer in the documentation
//	and/or other materials provided with the distribution.
//
//	* Neither the name of the author nor the names of its contributors may be used
//	to endorse or promote products derived from this software without specific
//	prior written permission.
//
//	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//	AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
//	IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//	DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
//	FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
//	DAMAGES (INCLUDING, BUT NOT LIMITED TO, PRPKUREMENT OF SUBSTITUTE GOODS OR
//	SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
//	CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
//	OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
//	OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

#import "PKAlgorithm.h"

/**
 *	Provides an interface for the Geometric Coordinatizer (GC) algorithm.
 */
@interface PKGeometricCoordinatizer : PKAlgorithm

#pragma mark -
#pragma mark Accessing

/**
 *	Flag used in association with the GC algorithm.
 *	Set it to YES if you wish to apply a reordering prior invoking the algorithm.
 */
@property (assign, nonatomic) BOOL reorderNodes;

#pragma mark -
#pragma mark Creating

/**
 *	The Geometric Coordinatizer (initial stage).
 *	Returns a reordered graph of a given "unordered" graph.
 *
 *	@param	graph				An edge-weighted, undirected graph.
 *	@param	start				A starting index.
 *	@param	finish				A finishing index (used in skinning mode).
 *	@param	flag				A reordering flag.
 *	@param	projectionType		A projection type (2D/3D).
 *  @param	completionHandler	A completion handler.
 *  @param	errorHandler		An error handler.
 *
 *	@return	The new algorithm operation.
 */
+ (instancetype)coordinatizerWithGraph:(id<PKGraphDelegate>)graph
                             fromIndex:(NSUInteger)start
                               toIndex:(NSUInteger)finish
                               reorder:(BOOL)flag
                        projectionType:(PKProjectionType)projectionType
                     completionHandler:(PKCompletionBlock)completionHandler
                          errorHandler:(PKErrorBlock)errorHandler;

#pragma mark -
#pragma mark Operating

/**
 *  Returns a reordering of nodes (graph) prior running the GC algorithm.
 *
 *  @param numberOfNodes		The number of nodes.
 *  @param numberOfDimensions	The number of dimensions.
 *
 *  @return A temporary graph used for storing nodes only.
 */
- (id<PKGraphDelegate>)reorderGraphWithLength:(NSUInteger)numberOfNodes
						   numberOfDimensions:(NSUInteger)numberOfDimensions;

@end
