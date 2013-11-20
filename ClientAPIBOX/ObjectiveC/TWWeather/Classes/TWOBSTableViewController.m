//
// TWOBSTableViewController.m
//
// Copyright (c) Weizhong Yang (http://zonble.net)
// All Rights Reserved
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
//     * Redistributions of source code must retain the above copyright
//       notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above copyright
//       notice, this list of conditions and the following disclaimer in the
//       documentation and/or other materials provided with the distribution.
//     * Neither the name of Weizhong Yang (zonble) nor the
//       names of its contributors may be used to endorse or promote products
//       derived from this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY WEIZHONG YANG ''AS IS'' AND ANY
// EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
// WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL WEIZHONG YANG BE LIABLE FOR ANY
// DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
// LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
// ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
// SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#import "TWOBSTableViewController.h"
#import "TWOBSResultTableViewController.h"
#import "TWErrorViewController.h"
#import "TWLoadingCell.h"
#import "TWAPIBox+Info.h"

@implementation TWOBSTableViewController
{
	NSMutableArray *_locations;
}

- (void)dealloc
{
	[_locations release];
	[super dealloc];
}

- (void)_init
{
	if (!_array) {
		_array = [[NSMutableArray alloc] init];
		NSArray *allLocations = [[TWAPIBox sharedBox] OBSLocations];
		for (NSDictionary *d in allLocations) {
			NSArray *items = d[@"items"];
			for (NSDictionary *item in items) {
				NSMutableDictionary *newItem = [NSMutableDictionary dictionaryWithDictionary:item];
				newItem[@"isLoading"] = @NO;
				[_array addObject:newItem];
			}
		}
	}
	if (!_filteredArray) {
		_filteredArray = [[NSMutableArray alloc] init];
	}

	if (!_locations) {
		_locations = [[NSMutableArray alloc] init];
		NSArray *allLocations = [[TWAPIBox sharedBox] OBSLocations];
		for (NSDictionary *d in allLocations) {
			NSMutableDictionary *category = [NSMutableDictionary dictionary];
			category[@"AreaID"] = d[@"AreaID"];
			category[@"areaName"] = d[@"areaName"];
			NSMutableArray *items = [NSMutableArray array];
			for (NSDictionary *item in d[@"items"]) {
				NSMutableDictionary *newItem = [NSMutableDictionary dictionaryWithDictionary:item];
				newItem[@"isLoading"] = @NO;
				[items addObject:newItem];
			}
			category[@"items"] = items;
			[_locations addObject:category];
		}
	}
}

- (id)initWithStyle:(UITableViewStyle)style
{
	if (self = [super initWithStyle:style]) {
		[self _init];
	}
	return self;
}
- (id)initWithCoder:(NSCoder *)decoder
{
	if (self = [super initWithCoder:decoder]) {
		[self _init];
	}
	return self;
}
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
		[self _init];
	}
	return self;
}

#pragma mark UIViewContoller Methods

- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	self.title = @"目前天氣";
	self.screenName = @"OBS List";
}

#pragma mark UITableViewDataSource and UITableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	if (tableView == self.tableView) {
		NSInteger count = [_locations count];
		if (count) {
			return count;
		}
	}
	else if (tableView == self.searchDisplayController.searchResultsTableView) {
		return 1;
	}
	return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if (tableView == self.tableView) {
		NSDictionary *sectionDictionary = _locations[section];
		NSArray *items = sectionDictionary[@"items"];
		NSInteger count = [items count];
		if (count) {
			return count;
		}
	}
	else if (tableView == self.searchDisplayController.searchResultsTableView) {
		return [_filteredArray count];
	}
	return 0;
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	if (tableView == self.tableView) {
		NSDictionary *sectionDictionary = _locations[section];
		return sectionDictionary[@"areaName"];
	}
	return nil;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *CellIdentifier = @"Cell";

	TWLoadingCell *cell = (TWLoadingCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) {
		cell = [[[TWLoadingCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
	}
	NSDictionary *dictionary = nil;
	if (tableView == self.tableView) {
		NSDictionary *sectionDictionary = _locations[indexPath.section];
		NSArray *items = sectionDictionary[@"items"];
		dictionary = items[indexPath.row];
	}
	else if (tableView == self.searchDisplayController.searchResultsTableView) {
		dictionary = _filteredArray[indexPath.row];
	}
	if (!dictionary) {
		return cell;
	}
	cell.textLabel.text = dictionary[@"name"];
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

	if ([dictionary[@"isLoading"] boolValue]) {
		[cell startAnimating];
	}
	else {
		[cell stopAnimating];
	}

	return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSMutableDictionary *dictionary	 = nil;
	if (tableView == self.tableView) {
		NSDictionary *sectionDictionary = _locations[indexPath.section];
		NSArray *items = sectionDictionary[@"items"];
		dictionary = items[indexPath.row];
	}
	else {
		dictionary = _filteredArray[indexPath.row];
	}
	if (dictionary) {
		NSString *identifier = dictionary[@"identifier"];
		dictionary[@"isLoading"] = @YES;
		self.tableView.userInteractionEnabled = NO;
		[self.tableView reloadData];
		[[TWAPIBox sharedBox] fetchOBSWithLocationIdentifier:identifier delegate:self userInfo:nil];
	}
}

#pragma mark -

- (void)resetLoading
{
	for (NSMutableDictionary *d in _filteredArray) {
		d[@"isLoading"] = @NO;
	}
	for (NSDictionary *d in _locations) {
		NSArray *items = d[@"items"];
		for (NSMutableDictionary *item in items) {
			item[@"isLoading"] = @NO;
		}
	}
	[self.tableView reloadData];
	[_searchController.searchResultsTableView reloadData];
	self.tableView.userInteractionEnabled = YES;
	_searchController.searchResultsTableView.userInteractionEnabled = YES;
}

#pragma mark -

- (void)APIBox:(TWAPIBox *)APIBox didFetchOBS:(id)result identifier:(NSString *)identifier userInfo:(id)userInfo
{
	[self resetLoading];

	if ([result isKindOfClass:[NSDictionary class]]) {
		TWOBSResultTableViewController *controller = [[TWOBSResultTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
		controller.title = result[@"locationName"];
		controller.description = result[@"description"];
		controller.rain = result[@"rain"];
		controller.temperature = result[@"temperature"];
		controller.time = result[@"time"];
		controller.windDirection = result[@"windDirection"];
		controller.windScale = result[@"windScale"];
		controller.gustWindScale = result[@"gustWindScale"];
		[self.navigationController pushViewController:controller animated:YES];
		[controller release];
	}
}
- (void)APIBox:(TWAPIBox *)APIBox didFailedFetchOBSWithError:(NSError *)error identifier:(NSString *)identifier userInfo:(id)userInfo
{
	[self resetLoading];
	[self pushErrorViewWithError:error];
}

@end
