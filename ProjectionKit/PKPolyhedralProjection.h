//
//  PKPolyhedralProjection.h
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

#import "PKTriangularProjection.h"

/**
 *	Provides an interface for the distance-preserving Polyhedral Projection (PP) algorithm.
 */
@interface PKPolyhedralProjection : PKTriangularProjection

#pragma mark -
#pragma mark Creating

/**
 *	The Polyhedral Projection (PP) algorithm.
 *	Returns the N-dimensional projection graph of the input graph.
 *
 *	@param	graph				An edge-weighted, undirected graph; each value in input is an array of values of a single variable for each data point.
 *	@param	start				A starting index.
 *	@param	dimensions			An array of dimensions (column indices).
 *	@param	minimumArea			A "Minimum Area" property flag.
 *	@param	minimumPerimeter	A "Minimum Perimeter" property flag.
 *	@param	mapNNC				A Nearest Neighbor Chain (NNC) mapping sequence flag.
 *	@param	mapEmanatingEdges	An emanating edges mapping sequence flag.
 *  @param	numberOfDimensions	The number of output dimensions.
 *  @param	numberOfIterations	The maximum number of iterations.
 *	@param	projectionType		A projection type (N-dimensional).
 *  @param	completionHandler	A completion handler.
 *  @param	errorHandler		An error handler.
 *
 *	@return	The new algorithm operation.
 */
+ (instancetype)polyhedralProjectionWithGraph:(id<PKGraphDelegate>)graph
									fromIndex:(NSUInteger)start
								   dimensions:(PKIntegerArray *)dimensions
								  minimumArea:(BOOL)minimumArea
							 minimumPerimeter:(BOOL)minimumPerimeter
									   mapNNC:(BOOL)mapNNC
							mapEmanatingEdges:(BOOL)mapEmanatingEdges
						   numberOfDimensions:(NSUInteger)numberOfDimensions
						   numberOfIterations:(NSUInteger)numberOfIterations
							   projectionType:(PKProjectionType)projectionType
							completionHandler:(PKCompletionBlock)completionHandler
								 errorHandler:(PKErrorBlock)errorHandler;

#pragma mark -
#pragma mark Accessing

/**
 *  Number of dimensions (ranging from 2, 3, and higher).
 */
@property (assign, nonatomic) NSUInteger numberOfDimensions;

@end
