import { createBrowserRouter } from 'react-router';
import { appRoutes } from './appRoutes';
import { basename, siteRoutes, withRoot } from './routes';

export const router = createBrowserRouter(withRoot([siteRoutes, ...appRoutes]), { basename });
